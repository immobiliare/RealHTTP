//
//  IndomioNetwork
//
//  Created by the Mobile Team @ ImmobiliareLabs
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Copyright ©2021 Immobiliare.it SpA. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

public class HTTPClientEventMonitor: NSObject {
    
    // MARK: - Private Properties
    
    /// Parent client.
    private weak var client: HTTPClientProtocol?
    
    /// Serial queue.
    private var queue = DispatchQueue(label: "com.httpclient.eventmonitor.queue")
    
    /// Map of the session/requests.
    private var requestTable = [URLSessionTask: HTTPRequestProtocol]()
    private var dataTable = [URLSessionTask: Data]()

    // MARK: - Initialization
    
    internal init(client: HTTPClientProtocol) {
        self.client = client
    }
    
    // MARK: - Internal Functions
    
    internal func addRequest(_ request: HTTPRequestProtocol, withTask task: URLSessionTask) {
        queue.sync {
            requestTable[task] = request
        }
    }
    
    internal func removeRequest(forTask task: URLSessionTask) {
        queue.sync {
            dataTable.removeValue(forKey: task)
            requestTable.removeValue(forKey: task)
        }
    }
    
    internal func request(forTask task: URLSessionTask) -> (request: HTTPRequestProtocol?, dataURL: Data?) {
        queue.sync {
            let data = dataTable[task]
            let request = requestTable[task]
            return (request, data)
        }
    }
    
}

// MARK: - URLSessionDelegate

extension HTTPClientEventMonitor: URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("didBecomeInvalidWithError")
    }
    
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("didReceive")
        
    }
    
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("urlSessionDidFinishEvents")
        
    }
    
    //define all  `NSURLSessionDataDelegate` and `NSURLSessionTaskDelegate` methods here
    //URLSessionDelegate methods
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            print("Progress \(downloadTask) \(progress)")
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let data = Data.fromURL(location, removeFile: true)
        queue.sync {
            dataTable[downloadTask] = data
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let (request, data) = request(forTask: task)
        guard let request = request, let client = self.client else {
            return
        }

        // Parse the response and create the object which contains all the datas.
        var response = HTTPRawResponse(request: request,
                                       urlRequest: task.originalRequest,
                                       client: client,
                                       response: task.response,
                                       data: data,
                                       error: error)
        response.currentRequest = task.currentRequest
        // Dispatch events
        didCompleteRequest(request, client: client, response: &response)
        
        // Cleanup
        removeRequest(forTask: task)
    }
    
}

// MARK: - Manage Responses for Tasks

extension HTTPClientEventMonitor {
    
    /// Called when request did complete.
    ///
    /// - Parameters:
    ///   - request: request.
    ///   - urlRequest: urlRequest executed.
    ///   - rawData: raw data.
    private func didCompleteRequest(_ request: HTTPRequestProtocol, client: HTTPClientProtocol, response: inout HTTPRawResponse) {
        let validationAction = client.validate(response: response)
        switch validationAction {
        case .failWithError(let error):
            // Response validation failed with error, set the new error and forward it
            response.error = HTTPError(.invalidResponse, error: error)
            didCompleteRequest(request, client: client, response: response)

        case .retryAfter(let altRequest):
            request.reset(retries: true)
            // Response validation failed, you can retry but we need to execute another call first.
            client.execute(request: altRequest).rawResponse(in: nil, { altResponse in
                request.reset(retries: true)
                client.execute(request: request)
            })
            
        case .retryIfPossible:
            request.currentRetry += 1
            
            guard request.currentRetry < request.maxRetries else {
                // Maximum number of retry attempts made.
                response.error = HTTPError(.maxRetryAttemptsReached)
                didCompleteRequest(request, client: client, response: response)
                return
            }
            
            // Reset the state and make another attempt
            request.reset(retries: false)
            client.execute(request: request)

        case .passed:
            // Passed, nothing to do
            didCompleteRequest(request, client: client, response: response)
        }
    }
    
    func didFailBuildingURLRequestFor(_ request: HTTPRequestProtocol, client: HTTPClientProtocol, error: Error) {
        let error = HTTPError(.failedBuildingURLRequest, error: error)
        let response = HTTPRawResponse(request: request, urlRequest: nil, client: client, error: error)
        didCompleteRequest(request, client: client, response: response)
    }
    
    func didCompleteRequest(_ request: HTTPRequestProtocol, client: HTTPClientProtocol, response: HTTPRawResponse) {
        request.receiveResponse(response, client: client)
    }
    
}
