//
//  IndomioHTTP
//
//  Created by the Mobile Team @ ImmobiliareLabs
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Copyright ©2021 Immobiliare.it SpA. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

public class HTTPClientEventMonitor: NSObject, URLSessionDelegate, URLSessionDataDelegate, URLSessionDownloadDelegate, URLSessionTaskDelegate, URLSessionStreamDelegate {
    
    // MARK: - Private Properties
    
    /// Parent client.
    internal private(set) weak var client: HTTPClientProtocol?
    
    var requests: [HTTPRequestProtocol] {
        queue.sync {
            Array(tasksToRequest.values)
        }
    }
    
    /// Serial queue.
    private var queue = DispatchQueue(label: "com.httpclient.eventmonitor.queue")
    
    /// Map of the session/requests.
    private var tasksToRequest = [URLSessionTask: HTTPRequestProtocol]()
    private var dataTable = [URLSessionTask: DataStream]()
    private var metricsTable = [URLSessionTask: HTTPRequestMetrics]()

    // MARK: - Initialization
    
    internal init(client: HTTPClientProtocol) {
        self.client = client
    }
    
    // MARK: - Internal Functions
    
    internal func addRequest(_ request: HTTPRequestProtocol, withTask task: URLSessionTask) {
        queue.sync {
            tasksToRequest[task] = request
        }
    }
    
    internal func removeRequest(forTask task: URLSessionTask) {
        queue.sync {
            dataTable.removeValue(forKey: task)
            tasksToRequest.removeValue(forKey: task)
            metricsTable.removeValue(forKey: task)
        }
    }
    
    internal func request(forTask task: URLSessionTask) -> (request: HTTPRequestProtocol?, dataURL: DataStream?, metrics: HTTPRequestMetrics?) {
        queue.sync {
            let data = dataTable[task]
            let request = tasksToRequest[task]
            let metrics = metricsTable[task]
            return (request, data, metrics)
        }
    }
    
    // MARK: - URLSession Delegate

    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        didReceiveSessionError(error)
    }
    
    // MARK: - Security Support
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        didChallangeAuthTask(task, challenge: challenge, completionHandler: completionHandler)
    }
    
    // MARK: - URLSessionDownloadTask
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let request = request(forTask: downloadTask).request,
              let fileURL = location.copyFileToDefaultLocation(task: downloadTask, forRequest: request) else {
            // copy file from a temporary location to a valid location
            return
        }
        
        queue.sync { dataTable[downloadTask] = DataStream(fileURL: fileURL) } // set data
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask,
                           willPerformHTTPRedirection response: HTTPURLResponse,
                           newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        didEvaluateRedirection(task: task, response: response, request: request, completion: completionHandler)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        didCompleteTask(task, didCompleteWithError: error)
    }
    
    // MARK: - Upload Progress
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        didProgressTask(task, kind: .upload, expectedLength: totalBytesExpectedToSend, currentLength: totalBytesSent)
    }
    
    // MARK: - Download Progress

    public func urlSession(_ session: Foundation.URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        didProgressTask(downloadTask, kind: .download, expectedLength: totalBytesExpectedToWrite, currentLength: totalBytesWritten)
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        didResumeDownloadTask(downloadTask, offset: fileOffset, totalLength: expectedTotalBytes)
    }

    // MARK: - URLSessionDataTask (Memory)
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        queue.sync {
            if dataTable[dataTask] == nil {
                dataTable[dataTask] = DataStream()
            }
            
            dataTable[dataTask]?.innerData?.append(data)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        queue.sync {
            let info = HTTPRequestMetrics(source: metrics, task: task)
            metricsTable[task] = info
            
            if let delegate = client?.delegate, let client = client, let request = tasksToRequest[task] {
                delegate.client(client, didCollectedMetricsFor: (request, task), metrics: info)
            }
        }
    }
    
    // MARK: - URLSessionStreamDelegate
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        guard let request = request(forTask: task).request else {
            return
        }

        if let streamContent = request.content as? HTTPStreamContent,
           let inputStream = streamContent.inputStream(recreate: true) {
            inputStream.open() // open the stream
            completionHandler(inputStream)
        }
        
    }
    
    // MARK: - Private Functions
    
    private func didEvaluateRedirection(task: URLSessionTask, response: HTTPURLResponse, request: URLRequest, completion: @escaping (URLRequest?) -> Void) {
        // missing components, continue to the default behaviour
        guard let client = client,
              let httpRequest = self.request(forTask: task).request else {
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
        
        let rawResponse = HTTPRawResponse(request: httpRequest, response: (response, nil, nil))
        // If delegate implements its own login we want to ask to him, if not we'll use the behaviour set
        // in `followRedirectsMode` of the parent client.
        let action = client.delegate?.client(client, willPerformRedirect: (httpRequest, task),
                                             response: rawResponse,
                                             newRequest: &newRequest) ??
            // default client behaviour, follow with copy or original system follow
            (client.followRedirectsMode == .followCopy ? .follow(newRequest) : .follow(request))
        
        switch action {
        case .follow(let newRouteRequest):
            completion(newRouteRequest)
        case .refuse:
            completion(nil)
        }
    }
    
    private func didReceiveSessionError(_ error: Error?) {
        for task in Array(tasksToRequest.keys) { // invalidate all requests
            let request = tasksToRequest[task]!
            var response = HTTPRawResponse(error: .sessionError, error: error, forRequest: request)
            didComplete(request: request, task: task, response: &response)
        }
    }
    
    private func didChallangeAuthTask(_ task: URLSessionTask, challenge: URLAuthenticationChallenge,
                                      completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard let request = request(forTask: task).request,
              let security = request.security ?? client?.security else { // use request's security or client security
            // if not security is settings for both client and request we can use the default handling
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        if let client = client {
            client.delegate?.client(client, didReceiveAuthChallangeFor: (request, task), authChallenge: challenge)
        }
        
        security.receiveChallenge(challenge, forRequest: request, task: task, completionHandler: completionHandler)
    }
    
    private func didResumeDownloadTask(_ task: URLSessionTask, offset: Int64, totalLength: Int64) {
        var progress = HTTPProgress(info: task.progress, percentage: 0)
        progress.kind = .download
        progress.resumedOffset = offset

        request(forTask: task).request?.receiveHTTPProgress(progress)
    }
    
    private func didProgressTask(_ task: URLSessionTask, kind: HTTPProgress.Kind, expectedLength: Int64, currentLength: Int64) {
        let slice = Float(1.0)/Float(expectedLength)
        let percentage = slice*Float(currentLength)
     
        var progress = HTTPProgress(info: task.progress, percentage: percentage)
        progress.kind = kind
        request(forTask: task).request?.receiveHTTPProgress(progress)
    }
    
    private func didCompleteTask(_ task: URLSessionTask, didCompleteWithError error: Error?) {
        if let client = self.client as? HTTPClientQueue,
              let operation = client.operationForTask(task) {
            operation.end() // mark the operation as finished
        }
        
        let (request, data, metrics) = request(forTask: task)
        guard let request = request else {
            return
        }
        
        guard !request.isCancelled else {
            // Operation is cancelled but it's complete.
            var response = HTTPRawResponse(error: .cancelled, forRequest: request)
            didComplete(request: request, task: task, response: &response)
            return
        }
        
        // Parse the response and create the object which contains all the datas including
        // metrics, requests and curl description.
        let rawResponse = (task.response, data, error)
        var response = HTTPRawResponse(request: request, response: rawResponse)
        response.attachURLRequests(original: task.originalRequest, current: task.currentRequest)
        response.metrics = metrics
        
        didComplete(request: request, task: task, response: &response)
        
        removeRequest(forTask: task)
    }
    
    /// Called when request did complete.
    ///
    /// - Parameters:
    ///   - request: request.
    ///   - urlRequest: urlRequest executed.
    ///   - rawData: raw data.
    private func didComplete(request: HTTPRequestProtocol, task: URLSessionTask, response: inout HTTPRawResponse) {
        guard let client = self.client else { return }
        
        let validationAction = client.validate(response: response, forRequest: request)
        
        switch validationAction {
        case .failWithError(let error): // Response validation failed with error, set the new error and forward it
            response.error = HTTPError(.invalidResponse, error: error)
            forwardHTTPResponseFor(request: request, task: task, response: response)
            
        case .retryAfter(let altRequest):
            request.reset(retries: true)
            
            if let queueClient = client as? HTTPClientQueue {
                do {
                    // Create a new operation for this request but link it with a dependency to the alt request
                    // so it will be executed in order (alt -> this).
                    let linkedOperation = try HTTPRequestOperation(task: queueClient.createTask(for: altRequest))
                    let thisOperation = try HTTPRequestOperation(task: queueClient.createTask(for: request))
                    thisOperation.addDependency(linkedOperation)
                    
                    queueClient.addOperations(linkedOperation, thisOperation)
                } catch {
                    response.error = HTTPError(.invalidResponse, error: error)
                    forwardHTTPResponseFor(request: request, task: task, response: response)
                }
            } else {
                // Response validation failed, you can retry but we need to execute another call first.
                let internalToken = altRequest.onRawResponse(queue: .main, { [weak self] response in
                    guard let self = self else { return }
                    guard response.raw.isError == false else {
                        // if retry fails we should avoid repeating the same alt call every time
                        self.forwardHTTPResponseFor(request: request, task: task, response: response.raw)
                        return
                    }
                    request.reset(retries: true)
                    client.execute(request: request)
                })
                altRequest.observers.markTokenAsPriority(internalToken)
                client.execute(request: altRequest)
            }
            
        case .retryIfPossible: // Retry if max retries has not be reached
            retryRequest(request: request, task: task,
                         response: &response, client: client,
                         afterInterval: nil)
            
        case .retryWithInterval(let retryInterval): // Retry if max retries has not be reached (with interval)
            retryRequest(request: request, task: task,
                         response: &response, client: client,
                         afterInterval: retryInterval)
            
        case .passed: // Passed, nothing to do
            forwardHTTPResponseFor(request: request, task: task, response: response)
        }
    }
    
    private func forwardHTTPResponseFor(request: HTTPRequestProtocol, task: URLSessionTask, response: HTTPRawResponse) {
        guard let client = client else { return }
        
        client.delegate?.client(client, didFinish: (request, task), response: response)
        request.receiveHTTPResponse(response, client: client)
    }
    
    private func retryRequest(request: HTTPRequestProtocol, task: URLSessionTask, response: inout HTTPRawResponse,
                              client: HTTPClientProtocol,
                              afterInterval: TimeInterval?) {
        
        func retryClosure() {
            // Reset the state and make another attempt
            request.reset(retries: false)
            client.execute(request: request)
        }
        
        request.currentRetry += 1
        
        guard request.currentRetry < request.maxRetries else {
            // Maximum number of retry attempts made.
            response.error = HTTPError(.maxRetryAttemptsReached)
            forwardHTTPResponseFor(request: request, task: task, response: response)
            return
        }
        
        if let afterInterval = afterInterval {
            DispatchQueue.global().asyncAfter(deadline: .now() + afterInterval) {
                retryClosure()
            }
        } else {
            retryClosure()
        }
        
    }

}
