//
//  RealHTTP
//
//  Created by the Mobile Team @ ImmobiliareLabs
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Copyright ©2021 Immobiliare.it SpA. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

internal class HTTPLegacyDataLoader: NSObject, HTTPDataLoader, URLSessionDelegate, URLSessionDataDelegate, URLSessionDownloadDelegate, URLSessionTaskDelegate, URLSessionStreamDelegate {
    
    
    // MARK: - Public Properties
        
    var queue = OperationQueue()

    // MARK: - Internal Properties
    
    /// URLSession instance which manage calls.
    internal var session: URLSession!
    
    /// Weak references to the parent HTTPClient instance.
    internal weak var client: HTTPClient?

    /// The cache policy for the request. Defaults to `.useProtocolCachePolicy`.
    /// Requests may override this behaviour.
    internal var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    
    // MARK: - Private Properties
    
    private var handlers = [URLSessionTask: DataLoaderResponse]()
        
    // MARK: - Initialization
    
    required init(configuration: URLSessionConfiguration,
                  maxConcurrentOperations: Int) {
        super.init()
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: queue)
        self.queue.maxConcurrentOperationCount = maxConcurrentOperations
    }
    
    // MARK: - Internal Function
    
    public func fetch(_ request: HTTPRequest) async throws -> HTTPResponse {
        guard let client = client else { throw HTTPError(.internal) }
        
        let sessionTask = try request.urlSessionTask(inClient: client)

        final class Box { var task: URLSessionTask? }
        
        let box = Box()
        return try await withTaskCancellationHandler(handler: {
            box.task?.cancel()
        }, operation: {
            try await withUnsafeThrowingContinuation({ continuation in
                box.task = self.loadData(with: request, task: sessionTask, completion: { response in
                    continuation.resume(returning: response)
                })
            })
        })
    }
    
    private func loadData(with request: HTTPRequest, task: URLSessionTask,
                          completion: @escaping DataLoaderResponse.Completion) -> URLSessionTask {
        session.delegateQueue.addOperation {
            let response = DataLoaderResponse(request: request, completion: completion)
            self.handlers[task] = response
        }
        task.resume()
        return task
    }
    

    // MARK: - Security Support
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        evaluateAuthChallange(task, challenge: challenge, completionHandler: completionHandler)
    }
    
    // MARK: - Core Operations

    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        didCompleteAllHandlersWithSessionError(error)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask,
                           didReceive data: Data) {
        handlers[dataTask]?.appendData(data)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask,
                           willPerformHTTPRedirection response: HTTPURLResponse,
                           newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        evaluateRedirect(task: task, response: response, request: request, completion: completionHandler)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask,
                           didCompleteWithError error: Error?) {
        completeTask(task, error: error)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    didFinishCollecting metrics: URLSessionTaskMetrics) {
        handlers[task]?.metrics = metrics
    }
    
    // MARK: - Upload Progress
    
    public func urlSession(_ session: URLSession, task: URLSessionTask,
                           didSendBodyData bytesSent: Int64,
                           totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {

        let progress = HTTPProgress(operation: .upload,
                                    progress: task.progress,
                                    currentLength: totalBytesSent, expectedLength: totalBytesExpectedToSend)
        handlers[task]?.request.progress = progress
    }
    
    // MARK: - Download Progress

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        guard let handler = handlers[downloadTask],
              let fileURL = location.copyFileToDefaultLocation(task: downloadTask,
                                                               forRequest: handler.request) else {
            // copy file from a temporary location to a valid location
            return
        }
        
        handler.dataFileURL = fileURL
        completeTask(downloadTask, error: nil)
    }
    
    public func urlSession(_ session: Foundation.URLSession, downloadTask: URLSessionDownloadTask,
                           didWriteData bytesWritten: Int64,
                           totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        let progress = HTTPProgress(operation: .download,
                                    progress: downloadTask.progress,
                                    currentLength: totalBytesWritten, expectedLength: totalBytesExpectedToWrite)
        handlers[downloadTask]?.request.progress = progress
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                           didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        
        let progress = HTTPProgress(progress: downloadTask.progress,
                                    currentLength: fileOffset, expectedLength: expectedTotalBytes)
        handlers[downloadTask]?.request.progress = progress
    }
    
    // MARK: - Stream
    
    public func urlSession(_ session: URLSession, task: URLSessionTask,
                           needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        guard let request = handlers[task]?.request else {
            return
        }

        if let streamContent = request.body.content as? HTTPStreamContent,
           let inputStream = streamContent.inputStream(recreate: true) {
            inputStream.open() // open the stream
            completionHandler(inputStream)
        }
    }
    
}

private extension HTTPLegacyDataLoader {
    
    func didCompleteAllHandlersWithSessionError(_ error: Error?) {
        let allHandlers = handlers.values
        handlers.removeAll()
        
        for handler in allHandlers {
            var response = HTTPResponse(errorType: .sessionError, error: error)
            response.request = handler.request
            handler.completion(response)
        }
    }
    
    func completeTask(_ task: URLSessionTask, error: Error?) {
        guard let handler = handlers[task] else {
            return
        }
        
        handlers[task] = nil
        
        let response = HTTPResponse(response: handler)
        handler.completion(response)
    }
    
    func evaluateRedirect(task: URLSessionTask, response: HTTPURLResponse, request: URLRequest, completion: @escaping (URLRequest?) -> Void) {
        // missing components, continue to the default behaviour
        guard let client = client else {
            completion(request)
            return
        }
        
        // For some reason both body, headers and method is not copied
        var newRequest = request
        
        if client.followRedirectsMode == .followCopy {
            // maintain http body, headers and method of the original request.
            newRequest.httpBody = task.originalRequest?.httpBody
            newRequest.allHTTPHeaderFields = task.originalRequest?.allHTTPHeaderFields
            newRequest.httpMethod = task.originalRequest?.httpMethod
        }
        
        // If delegate implements its own login we want to ask to him, if not we'll use the behaviour set
        // in `followRedirectsMode` of the parent client.
        let action: HTTPRedirectAction = (client.followRedirectsMode == .followCopy ? .follow(newRequest) : .follow(request))
        
        switch action {
        case .follow(let newRouteRequest):
            completion(newRouteRequest)
        case .refuse:
            completion(nil)
        }
    }
    
    func evaluateAuthChallange(_ task: URLSessionTask, challenge: URLAuthenticationChallenge,
                                      completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let request = handlers[task]?.request,
              let security = request.security ?? client?.security else {
            // if not security is settings for both client and request we can use the default handling
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        // use request's security or client security
        security.receiveChallenge(challenge, forRequest: request, task: task, completionHandler: completionHandler)
    }
    
}
