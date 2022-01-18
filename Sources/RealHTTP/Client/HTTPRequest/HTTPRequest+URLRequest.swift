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

extension HTTPRequest {
    
    /// Create the task to execute in an `URLSession` instance.
    ///
    /// - Parameter client: client where the query should be executed.
    /// - Returns: `URLSessionTask`
    internal func urlSessionTask(inClient client: HTTPClient) throws -> URLSessionTask {
        // Generate the `URLRequest` instance.
        let urlRequest = try urlRequest(inClient: client)
        
        // Create the `URLSessionTask` instance.
        var task: URLSessionTask!
        if urlRequest.hasStream {
            // If specified a stream mode we want to create the appropriate task
            task = client.session.uploadTask(withStreamedRequest: urlRequest)
        } else {
            switch transferMode {
            case .default:
                task = client.session.dataTask(with: urlRequest)
            case .largeData:
                //if let resumeData = resumeData {
                  //  task = client.session.downloadTask(withResumeData: resumeData)
                //} else {
                    task = client.session.downloadTask(with: urlRequest)
                //}
            }
        }
        
        /// Keep in mind it's just a suggestion for HTTP/2 based services.
        task.priority = httpPriority.urlTaskPriority
        return task
    }
    
    // MARK: - Private Functions
    
    /// Create the `URLRequest` instance for a client instance.
    ///
    /// - Parameter client: client instance.
    /// - Returns: `URLRequest`
    private func urlRequest(inClient client: HTTPClient) throws -> URLRequest {
        guard let fullURL = urlComponents.fullURLInClient(client) else {
            throw HTTPError(.invalidURL)
        }
        
        let requestCachePolicy = cachePolicy ?? client.cachePolicy
        let requestTimeout = timeout ?? client.timeout
        let requestHeaders = (client.headers + headers)

        // Prepare the request
        var urlRequest = try URLRequest(url: fullURL,
                                        method: method,
                                        cachePolicy: requestCachePolicy,
                                        timeout: requestTimeout,
                                        headers: requestHeaders)
        try urlRequest.setHTTPBody(body) // setup the body
        return urlRequest
    }
    
}
