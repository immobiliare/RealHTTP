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

public protocol HTTPClientProtocol: AnyObject {
    
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
    var validators: [HTTPResponseValidator] { get set }
    
    /// The cache policy for the request. Defaults to `.useProtocolCachePolicy`.
    /// Requests may override this behaviour.
    var cachePolicy: URLRequest.CachePolicy { get set }
    
    // MARK: - Public Functions
    
    /// Validate response from a request.
    ///
    /// - Parameter response: response.
    func validate(response: HTTPRawResponse) -> HTTPResponseValidatorAction

    /// Create the best subclass of `URLSessionTask` to execute the request.

    /// - Parameter request: request to use.
    func createTask(for request: HTTPRequestProtocol) throws -> URLSessionTask
    
    @discardableResult
    func execute(request: HTTPRequestProtocol) -> HTTPRequestProtocol

}

// MARK: - HTTPClientProtocol Configuration

public extension HTTPClientProtocol {
    
    /// Create the URLSessionTask for request.
    ///
    /// - Parameter request: request.
    /// - Throws: throw an exception if `URLRequest` failed to be generated.
    /// - Returns: (URLRequest, URLSessionTask)
    func createTask(for request: HTTPRequestProtocol) throws -> URLSessionTask {
        let urlRequest = try request.urlRequest(in: self)
        switch request.expectedDataType {
        case .default:
            return session.dataTask(with: urlRequest)
        case .large:
            if let resumeDataURL = request.resumeDataURL,
               let resumeData = Data.fromURL(resumeDataURL) {
                return session.downloadTask(withResumeData: resumeData)
            } else {
                return session.downloadTask(with: urlRequest)
            }
        }
    }
    
    /// Validate the response with the list of validators.
    ///
    /// - Parameters:
    ///   - clientValidators: validators list.
    ///   - response: response received from server.
    /// - Returns: HTTPResponseValidatorAction
    func validate(response: HTTPRawResponse) -> HTTPResponseValidatorAction {
        for validator in validators {
            let result = validator.validate(response: response)
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
