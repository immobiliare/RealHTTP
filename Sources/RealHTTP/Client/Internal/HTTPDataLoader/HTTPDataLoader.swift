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
    private var dataLoadersMap = ThreadSafeDictionary<Int, HTTPDataLoaderResponse>()
    
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
        
        let sessionTask = try await request.urlSessionTask(inClient: client)
        request.sessionTask = sessionTask
        request.client = nil
        
        let box = Box()
        return try await withTaskCancellationHandler(operation: {
            // Conversion of the callback system to the async/await version.
            let response: HTTPResponse = try await withUnsafeThrowingContinuation({ continuation in
                box.task = self.fetch(request, task: sessionTask, completion: { [weak self] response in
                    do { // Apply optional transformers.
                        let tResponse = try self?.applyResponseTransformers(to: response, request: request) ?? response
                        // continue the async/await operation
                        continuation.resume(returning: tResponse)
                    } catch {
                        continuation.resume(with: .failure(error))
                    }
                })
            })

            /// Once we receive the response we would to use validators to validate received response.
            /// It evaluates each validator in order and stops to the first one who send a non `.success`
            /// response. Validator return the action to perform in case of failure.
            let validationAction = self.client!.validate(response: response, forRequest: request)

            if request.isAltRequest {
                // request pass validator but ignore it's response. you can retry an alt request.
                return response
            }
            
            switch validationAction {
            case .failChain(let error):
                // Fail operation due to validation trigger. We want to attach this message
                // to the original response received.
                response.setError(category: .validatorFailure, error)
                return response
                
            case .retry(let strategy):
                
                // Perform a retry attempt using specified strategy.
                guard request.currentRetry < request.maxRetries else {
                    // retry strategy cannot be executed if call is an alternate request
                    // created as retry strategy, otherwise we'll get an infinite loop.
                    // In this case we want just return the response itself.
                    response.error?.category = .retryAttemptsReached
                    return response
                }
                
                // Perform the retry strategy to apply and return the result
                let retryResponse = try await performRetryStrategy(strategy,
                                                                   forRequest: request, task: sessionTask,
                                                                   withResponse: response)
                return retryResponse
                
            case .nextValidator:
                // Everything goes fine, we want to return the response of the call.
                return response
                
            case .nextValidatorWithResponse(let modifiedResponse):
                // Everything goes fine, we want to return the response of the call and modify the original response.
                return modifiedResponse
                
            }
        }, onCancel: {
            // Support for task cancellation
            box.task?.cancel()
            
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
        
        if request.isAltRequest {
            DispatchQueue.main.async { [weak self] in
                guard let client = self?.client else { return }
                client.delegate?.client(client, request: (request, task),
                                        willRetryWithStrategy: strategy,
                                        afterResponse: response)
            }
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
       
            // try again the same request and increment the attempts counter
            let originalRequestResponse = try await self.fetch(request)
            return originalRequestResponse
            
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
        session.delegateQueue.addOperation { [weak self] in
            guard let self = self else { return }
            
            request.client = self.client
            let response = HTTPDataLoaderResponse(request: request, completion: completion)
            
            // URLSession's finish delegate is called on a secondary thread so it may happens
            // multiple finished calls attempt to modify the dataLoadersMap dictionary causing
            // this crash <https://github.com/immobiliare/RealHTTP/issues/44>
            self.dataLoadersMap[task.taskIdentifier] = response
            
            DispatchQueue.main.async { [weak self] in
                guard let client = self?.client else { return }
                client.delegate?.client(client, didEnqueue: (request, task))
            }
        }
        task.resume()
        return task
    }
    
    /// Apply transformers of client to a received response.
    ///
    /// - Parameters:
    ///   - response: response.
    ///   - request: origin request.
    /// - Returns: `HTTPResponse`
    func applyResponseTransformers(to response: HTTPResponse, request: HTTPRequest) throws -> HTTPResponse {
        guard let transformers =  client?.responseTransformers, transformers.isEmpty == false else {
            return response
        }
        
        var tResponse = response
        try transformers.forEach {
            tResponse = try $0.transform(response: tResponse, ofRequest: request)
        }
        
        return tResponse
    }
    
    // MARK: - Security Support
    
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        evaluateAuthChallange(task, challenge: challenge, completionHandler: completionHandler)
    }
    
    // MARK: - Core Operations

    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        didCompleteAllHandlersWithSessionError(error)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask,
                           didReceive data: Data) {
        self.dataLoadersMap[dataTask.taskIdentifier]?.appendData(data)
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
        let handler = dataLoadersMap[task.taskIdentifier]
        completeTask(task, handler: handler, error: error)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    didFinishCollecting metrics: URLSessionTaskMetrics) {
        
        // Metrics may fire after URLSession:task:didCompleteWithError: is called, delegate may be nil
        guard let handler = self.dataLoadersMap[task.taskIdentifier] else { return }
        
        let httpMetrics = HTTPMetrics(metrics: metrics, task: task)
        handler.sessionTaskMetrics = metrics
        handler.httpMetrics = httpMetrics
        
        if let httpMetrics = httpMetrics {
            DispatchQueue.main.async { [weak self] in
                guard let client = self?.client else { return }
                client.delegate?.client(client, didCollectedMetricsFor: (handler.request, task), metrics: httpMetrics)
            }
        }
    }
    
    // MARK: - Upload Progress
    
    public func urlSession(_ session: URLSession, task: URLSessionTask,
                           didSendBodyData bytesSent: Int64,
                           totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {

        let progress = HTTPProgress(event: .upload,
                                    progress: task.progress,
                                    currentLength: totalBytesSent, expectedLength: totalBytesExpectedToSend)
        dataLoadersMap[task.taskIdentifier]?.request.progress = progress
    }
    
    // MARK: - Download Progress

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        guard let handler = dataLoadersMap[downloadTask.taskIdentifier],
              let fileURL = location.copyFileToDefaultLocation(task: downloadTask,
                                                               forRequest: handler.request) else {
            // copy file from a temporary location to a valid location
            return
        }
        
        handler.dataFileURL = fileURL
        completeTask(downloadTask, handler: handler, error: nil)
    }
    
    public func urlSession(_ session: Foundation.URLSession, downloadTask: URLSessionDownloadTask,
                           didWriteData bytesWritten: Int64,
                           totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        let progress = HTTPProgress(event: .download,
                                    progress: downloadTask.progress,
                                    currentLength: totalBytesWritten, expectedLength: totalBytesExpectedToWrite)
        
        self.dataLoadersMap[downloadTask.taskIdentifier]?.request.progress = progress
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                           didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        
        let progress = HTTPProgress(event: .resumed,
                                    progress: downloadTask.progress,
                                    currentLength: fileOffset,
                                    expectedLength: expectedTotalBytes)
        
        self.dataLoadersMap[downloadTask.taskIdentifier]?.request.progress = progress
    }
    
    // MARK: - Stream
    
    public func urlSession(_ session: URLSession, task: URLSessionTask,
                           needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        guard let request = dataLoadersMap[task.taskIdentifier]?.request else {
            return
        }

        if let streamContent = request.body.content as? HTTPBody.StreamContent,
           let inputStream = streamContent.inputStream(recreate: true).stream {
            inputStream.open() // open the stream
            completionHandler(inputStream)
        }
    }
    
    // MARK: - Other Events
    
    func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        guard let request = dataLoadersMap[task.taskIdentifier]?.request else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let client = self?.client else { return }
            client.delegate?.client(client, taskIsWaitingForConnectivity: (request, task))
        }
    }
    
}

// MARK: - HTTPLegacyDataLoader (Helper Functions)

private extension HTTPDataLoader {
    
    /// This method is called when session is not valid anymore and all requests cannot be
    /// performed by the system.
    ///
    /// - Parameter error: error generated.
    func didCompleteAllHandlersWithSessionError(_ error: Error?) {
        /*let allHandlers = dataLoadersMap.values
        dataLoadersMap.removeAll()
        
        for handler in allHandlers {
            let response = HTTPResponse(errorType: .sessionError, error: error)
            response.request = handler.request
            
            // Reset the link to the client
            handler.request.client = nil
            handler.request.sessionTask = nil
            
            handler.completion(response)
        }*/
    }
    
    /// Method called to perform finalization of a request and return of the operation.
    ///
    /// - Parameters:
    ///   - task: target task finished.
    ///   - handler: response received.
    ///   - error: error received, if any.
    func completeTask(_ task: URLSessionTask, handler: HTTPDataLoaderResponse?, error: Error?) {
        guard let handler = handler else {
            return
        }
        
        self.dataLoadersMap[task.taskIdentifier]?.urlResponse = task.response

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
            handler.dataFileURL = resumableData.writeToTemporaryFile(fileName: handler.request.downloadFileName)
        }
        
        handler.urlRequests = (task.originalRequest, task.currentRequest)
        
        if let error = error {
            handler.error = error
        }
        
        self.dataLoadersMap[task.taskIdentifier] = nil
        
        let response = HTTPResponse(response: handler)
        handler.completion(response)
        
        DispatchQueue.main.async { [weak self] in
            guard let client = self?.client else { return }
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
        let handler = dataLoadersMap[task.taskIdentifier]
        guard let client = client, let handler = handler else {
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
        guard let request = dataLoadersMap[task.taskIdentifier]?.request,
              let security = request.security ?? client?.security else {
            // if not security is settings for both client and request we can use the default handling
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let client = self?.client else { return }
            client.delegate?.client(client, didReceiveAuthChallangeFor: (request, task), authChallenge: challenge)
        }
        
        // use request's security or client security
        security.service().receiveChallenge(challenge, forRequest: request, task: task, completionHandler: completionHandler)
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
