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

/// This define the structure of a client where you can execute your HTTP requests.
public protocol HTTPClientProtocol: AnyObject {
    
    // MARK: - Public Properties
    
    /// Delegate for events of the client.
    var delegate: HTTPClientDelegate? { get set }
    
    /// Base URL.
    var baseURL: String { get set }
    
    /// Service's URLSession instance to use.
    var session: URLSession! { get set }
    
    /// Headers which are part of each request made using the client.
    var headers: HTTPHeaders { get set }

    /// Timeout interval for requests. Defaults to `60` seconds.
    /// Requests may override this behaviour.
    var timeout: TimeInterval { get set }
    
    /// Validators for response. Values are executed in order.
    var validators: [HTTPResponseValidatorProtocol] { get set }
    
    /// The cache policy for the request. Defaults to `.useProtocolCachePolicy`.
    /// Requests may override this behaviour.
    var cachePolicy: URLRequest.CachePolicy { get set }
    
    /// Allows you to set the proper security authentication methods.
    /// Requests may override this behaviour.
    var security: HTTPSecurityProtocol? { get set }
    
    // MARK: - Validation of Response
    
    /// Validate response from a request.

    /// - Parameters:
    ///   - response: response received.
    ///   - request: origin request.
    func validate(response: HTTPRawResponse, forRequest request: HTTPRequestProtocol) -> HTTPResponseValidatorResult

    // MARK: - Requests Builder

    /// Create the best subclass of `URLSessionTask` to execute the request.

    /// - Parameter request: request to use.
    func createTask(for request: HTTPRequestProtocol) throws -> URLSessionTask
    
    // MARK: - Executing Requests
    
    /// Execute network request asynchrously.
    ///
    /// - Parameter request: request to execute.
    @discardableResult
    
    func execute(request: HTTPRequestProtocol) -> HTTPRequestProtocol
    
    /// Execute network request synchrously.
    ///
    /// - Parameter request: request to execute.
    @discardableResult
    func executeSync(request: HTTPRequestProtocol) -> HTTPRawResponse
    
}

// MARK: - HTTPClientProtocol Configuration

public extension HTTPClientProtocol {
    
    /// Create the URLSessionTask for request.
    ///
    /// - Parameter request: request.
    /// - Throws: throw an exception if `URLRequest` failed to be generated.
    /// - Returns: (URLRequest, URLSessionTask)
    func createTask(for request: HTTPRequestProtocol) throws -> URLSessionTask {
        if request.isCancelled {
            throw HTTPError(.cancelled) // we don't need to create a session task for a cancelled event
        }
        
        let urlRequest = try request.urlRequest(in: self)
        var task: URLSessionTask!
        
        if urlRequest.httpBodyStream != nil {
            // If specified a stream mode we want to create the appropriate task
            task = session.uploadTask(withStreamedRequest: urlRequest)
        } else {
            switch request.transferMode {
            case .default:
                task = session.dataTask(with: urlRequest)
            case .largeData:
                if let resumeData = request.resumeData {
                    task = session.downloadTask(withResumeData: resumeData)
                } else {
                    task = session.downloadTask(with: urlRequest)
                }
            }
        }
        
        /// Keep in mind it's just a suggestion for HTTP/2 based services.
        task.priority = request.priority.urlTaskPriority
        request.task = task
        return task
    }
    
    /// Validate the response using the ordered list of validators.
    ///
    /// - Parameters:
    ///   - response: response received from server.
    ///   - request: origin request.
    /// - Returns: HTTPResponseValidatorAction
    func validate(response: HTTPRawResponse, forRequest request: HTTPRequestProtocol) -> HTTPResponseValidatorResult {
        for validator in validators {
            let result = validator.validate(response: response, forRequest: request)
            guard case .passed = result else {
                return result
            }
        }
        
        return .passed
    }
    
    /// Set base url.
    ///
    /// - Parameter url: base url.
    /// - Returns: Self
    func baseURL(_ url: String) -> Self {
        self.baseURL = url
        return self
    }
    
    /// Set header name with value.
    ///
    /// - Parameters:
    ///   - name: name of the header.
    ///   - value: value of the header.
    /// - Returns: Self
    func header(_ name: HTTPHeaderField, _ value: String) -> Self {
        self.headers[name] = value
        return self
    }
    
    /// Set multiple headers.
    ///
    /// - Parameter headers: headers.
    /// - Returns: Self
    func headers(_ builder: ((inout HTTPHeaders) -> Void)) -> Self {
        builder(&headers)
        return self
    }
    
    /// Set the request timeout interval.
    /// If not set the `HTTPClient`'s timeout where the instance is running will be used.
    /// - Parameter timeout: timeout interval in seconds.
    /// - Returns: Self
    func timeout(_ timeout: TimeInterval) -> Self {
        self.timeout = timeout
        return self
    }
    
    
}
