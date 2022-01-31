//
//  RealHTTP
//  Lightweight Async/Await Network Layer/Stubber for Swift
//
//  Created & Maintained by Mobile Platforms Team @ ImmobiliareLabs.it
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Authors:
//   - Daniele Margutti <hello@danielemargutti.com>
//
//  Copyright ©2022 Immobiliare.it SpA.
//  Licensed under MIT License.
//

import Foundation

/// This class is used to perform async/await operation by using the standard
/// URLSessionDelegate which can be used from iOS 13+.
/// This because new `URLSession` methods are introduced and available only starting from iOS 15+.
internal class HTTPDataLoader: NSObject,
                               URLSessionDelegate, URLSessionDataDelegate,
                               URLSessionDownloadDelegate,
                               URLSessionTaskDelegate, URLSessionStreamDelegate {

    // MARK: - Internal Properties
    
    /// URLSession instance which manage calls.
    internal var session: URLSession!
    
    /// Weak references to the parent HTTPClient instance.
    internal weak var client: HTTPClient?

    /// The cache policy for the request. Defaults to `.useProtocolCachePolicy`.
    /// Requests may override this behaviour.
    internal var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    
    // MARK: - Private Properties
    
    /// Operation queue.
    private var queue = OperationQueue()
    
    /// List of active running operations.
    private var dataLoadersMap = [URLSessionTask: HTTPDataLoaderResponse]()
        
    // MARK: - Initialization
    
    /// Initialize a new client configuration.
    ///
    /// - Parameters:
    ///   - configuration: configuration setting.
    ///   - maxConcurrentOperations: number of concurrent operations.
    required init(configuration: URLSessionConfiguration,
                  maxConcurrentOperations: Int) {
        super.init()
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: queue)
        self.queue.maxConcurrentOperationCount = maxConcurrentOperations
    }
    
    // MARK: - Internal Function
    
    /// Perform fetch of the request in background and return the response asynchrously.
    ///
    /// - Parameter request: request to execute.
    /// - Returns: `HTTPResponse`
    public func fetch(_ request: HTTPRequest) async throws -> HTTPResponse {
        guard let client = client else {
            throw HTTPError(.internal)
        }
        
        let sessionTask = try request.urlSessionTask(inClient: client)
        request.sessionTask = sessionTask
        request.client = nil
        
        let box = Box()
        return try await withTaskCancellationHandler(handler: {
            // Support for task cancellation
            box.task?.cancel()
        }, operation: {
            // Conversion of the callback system to the async/await version.
            let response = try await withUnsafeThrowingContinuation({ continuation in
                box.task = self.fetch(request, task: sessionTask, completion: { response in
                    // continue the async/await operation
                    continuation.resume(returning: response)
                })
            })

            /// Once we receive the response we would to use validators to validate received response.
            /// It evaluates each validator in order and stops to the first one who send a non `.success`
            /// response. Validator return the action to perform in case of failure.
            let validationAction = self.client!.validate(response: response, forRequest: request)
            switch validationAction {
            case .failChain(let error):
                // Fail network operation with given error object.
                return HTTPResponse(error: error)
                
            case .retry(let strategy):
                // Perform a retry attempt using specified strategy.
                if request.isAltRequest || request.currentRetry > request.maxRetries {
                    // retry strategy cannot be executed if call is an alternate request
                    // created as retry strategy, otherwise we'll get an infinite loop.
                    // In this case we want just return the response itself.
                    return response
                } else {
                    // Perform the retry strategy to apply and return the result
                    let retryResponse = try await performRetryStrategy(strategy,
                                                                       forRequest: request, task: sessionTask,
                                                                       withResponse: response)
                    return retryResponse
                }
                
            case .nextValidator:
                // Everything goes fine, we want to return the response of the call.
                return response
            }
        })
    }
    
    /// Execute the retry strategy if one of the client's validator wants it.
    ///
    /// - Parameters:
    ///   - strategy: strategy to execute for retry.
    ///   - request: request who failed to be validated.
    ///   - response: response received from the request failed.
    /// - Returns: `HTTPResponse`
    private func performRetryStrategy(_ strategy: HTTPRetryStrategy,
                                      forRequest request: HTTPRequest, task: URLSessionTask,
                                      withResponse response: HTTPResponse) async throws -> HTTPResponse {
        
        if request.isAltRequest, let client = self.client {
            client.delegate?.client(client, request: (request, task),
                                    willRetryWithStrategy: strategy,
                                    afterResponse: response)
        }
        
        switch strategy {
        case .after(let altRequest, let delayToRetryMainCall, let catcher):
            // If `request` did fail we want to execute an alternate request and retry again the original one.
            // An example of this case is the auth expiration; we want to perform an authentication refresh
            // and retry again the original call.
            altRequest.isAltRequest = true
            request.currentRetry += 1
            let altRequestResponse = try await self.fetch(altRequest)
            // we can specify an async callback function to execute once we receive the response of the alt request.
            // (in the example above we would use it to setup and store the authentication data received before retry the call).
            try await catcher?(altRequest, altRequestResponse)
            // wait before retry the original call, if set.
            try await Task.sleep(seconds: delayToRetryMainCall)
            
            return response
            
        default:
            // Retry mechanism is made with a specified interval.
            // wait a certain amount of time depending by the strategy set...
            try await Task.sleep(seconds: strategy.retryInterval(forRequest: request))
            // try again the same request and increment the attempts counter
            request.currentRetry += 1
            let response = try await self.fetch(request)
            return response
        }
    }
    
    /// Fetch function which uses a callback.
    ///
    /// - Parameters:
    ///   - request: request to execute.
    ///   - task: task to execute.
    ///   - completion: completion block to call at the end of the operation.
    /// - Returns: `URLSessionTask`
    private func fetch(_ request: HTTPRequest, task: URLSessionTask,
                       completion: @escaping HTTPDataLoaderResponse.Completion) -> URLSessionTask {
        session.delegateQueue.addOperation {
            let response = HTTPDataLoaderResponse(request: request, completion: completion)
            self.dataLoadersMap[task] = response
            
            if let client = self.client {
                client.delegate?.client(client, didEnqueue: (request, task))
            }
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
        dataLoadersMap[dataTask]?.appendData(data)
    }
    
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        evaluateRedirect(task: task, response: response, request: request, completion: completionHandler)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask,
                           didCompleteWithError error: Error?) {
        completeTask(task, error: error)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    didFinishCollecting metrics: URLSessionTaskMetrics) {
        dataLoadersMap[task]?.metrics = metrics
        
        if let delegate = client?.delegate, let client = client,
            let request = dataLoadersMap[task],
           let metrics = HTTPMetrics(metrics: metrics) {
            delegate.client(client, didCollectedMetricsFor: (request.request, task), metrics: metrics)
        }
    }
    
    // MARK: - Upload Progress
    
    public func urlSession(_ session: URLSession, task: URLSessionTask,
                           didSendBodyData bytesSent: Int64,
                           totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {

        let progress = HTTPProgress(event: .upload,
                                    progress: task.progress,
                                    currentLength: totalBytesSent, expectedLength: totalBytesExpectedToSend)
        dataLoadersMap[task]?.request.progress = progress
    }
    
    // MARK: - Download Progress

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        guard let handler = dataLoadersMap[downloadTask],
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
        
        let progress = HTTPProgress(event: .download,
                                    progress: downloadTask.progress,
                                    currentLength: totalBytesWritten, expectedLength: totalBytesExpectedToWrite)
        dataLoadersMap[downloadTask]?.request.progress = progress
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                           didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        
        let progress = HTTPProgress(event: .resumed,
                                    progress: downloadTask.progress,
                                    currentLength: fileOffset,
                                    expectedLength: expectedTotalBytes)
        dataLoadersMap[downloadTask]?.request.progress = progress
    }
    
    // MARK: - Stream
    
    public func urlSession(_ session: URLSession, task: URLSessionTask,
                           needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        guard let request = dataLoadersMap[task]?.request else {
            return
        }

        if let streamContent = request.body.content as? HTTPStreamContent,
           let inputStream = streamContent.inputStream(recreate: true) {
            inputStream.open() // open the stream
            completionHandler(inputStream)
        }
    }
    
    // MARK: - Other Events
    
    func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        guard let client = self.client,
              let request = dataLoadersMap[task]?.request else {
            return
        }
        
        client.delegate?.client(client, taskIsWaitingForConnectivity: (request, task))
    }
    
}

// MARK: - HTTPLegacyDataLoader (Helper Functions)

private extension HTTPDataLoader {
    
    /// This method is called when session is not valid anymore and all requests cannot be
    /// performed by the system.
    ///
    /// - Parameter error: error generated.
    func didCompleteAllHandlersWithSessionError(_ error: Error?) {
        let allHandlers = dataLoadersMap.values
        dataLoadersMap.removeAll()
        
        for handler in allHandlers {
            var response = HTTPResponse(errorType: .sessionError, error: error)
            response.request = handler.request
            
            // Reset the link to the client
            handler.request.client = nil
            handler.request.sessionTask = nil
            
            handler.completion(response)
        }
    }
    
    /// Method called to perform finalization of a request and return of the operation.
    ///
    /// - Parameters:
    ///   - task: target task finished.
    ///   - error: error received, if any.
    func completeTask(_ task: URLSessionTask, error: Error?) {
        dataLoadersMap[task]?.urlResponse = task.response
        
        guard let handler = dataLoadersMap[task] else {
            return
        }
        
        if handler.request.transferMode == .largeData,
            let error = error, let  nsError = error as NSError?,
           let resumableData = nsError.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
            // When download fails task will be completed with an error and the error contains
            // a resumable set of data.
            // <https://developer.apple.com/forums/thread/24770>
            handler.request.progress = HTTPProgress(event: .failed,
                                                    currentLength: 0,
                                                    expectedLength: 0, partialData: resumableData)
            // Also store the resumable data on response
            handler.dataFileURL = resumableData.writeToTemporaryFile()
        }
        
        // Reset the link to the client
        handler.request.client = nil
        handler.request.sessionTask = nil
        
        handler.urlRequests = (task.originalRequest, task.currentRequest)
        
        if let error = error {
            handler.error = error
        }
        
        dataLoadersMap[task] = nil
        
        let response = HTTPResponse(response: handler)
        handler.completion(response)
        
        if let client = self.client {
            client.delegate?.client(client, didFinish: (handler.request, task), response: response)
        }
    }
    
    /// Evaluate redirect of the requests.
    ///
    /// - Parameters:
    ///   - task: task to execute.
    ///   - response: response received.
    ///   - request: original request executed.
    ///   - completion: completion block.
    func evaluateRedirect(task: URLSessionTask, response: HTTPURLResponse, request: URLRequest,
                          completion: @escaping (URLRequest?) -> Void) {
        // missing components, continue to the default behaviour
        guard let client = client, let handler = dataLoadersMap[task] else {
            completion(request)
            return
        }
        
        handler.urlResponse = response
        
        let redirectMode = handler.request.redirectMode ?? client.redirectMode

        // For some reason both body, headers and method is not copied
        var redirectRequest: URLRequest?

        switch redirectMode {
        case .follow:
            redirectRequest = request
        case .followWithOriginalSettings:
            // maintain http body, headers and method of the original request.
            redirectRequest = request
            redirectRequest?.httpBody = task.originalRequest?.httpBody
            redirectRequest?.allHTTPHeaderFields = task.originalRequest?.allHTTPHeaderFields
            redirectRequest?.httpMethod = task.originalRequest?.httpMethod
        case .followCustom(let urlRequestBuilder):
            redirectRequest = urlRequestBuilder(request)
        case .refuse:
            redirectRequest = nil
        }
        
        completion(redirectRequest)
    }
    
    /// Evaluate authentication challange with the security option set.
    ///
    /// - Parameters:
    ///   - task: task to execute.
    ///   - challenge: challange.
    ///   - completionHandler: completion callback.
    func evaluateAuthChallange(_ task: URLSessionTask, challenge: URLAuthenticationChallenge,
                                      completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let request = dataLoadersMap[task]?.request,
              let security = request.security ?? client?.security else {
            // if not security is settings for both client and request we can use the default handling
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        if let client = client {
            client.delegate?.client(client, didReceiveAuthChallangeFor: (request, task), authChallenge: challenge)
        }
        
        // use request's security or client security
        security.receiveChallenge(challenge, forRequest: request, task: task, completionHandler: completionHandler)
    }
    
}

extension HTTPDataLoader {
    
    /// Support class for incapsulation of the task.
    private final class Box {
        var task: URLSessionTask?
    }

}

extension Task where Success == Never, Failure == Never {
    
    static func sleep(seconds: Double) async throws {
        guard seconds > 0 else {
            return
        }
        
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
    
}
