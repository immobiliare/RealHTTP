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

public typealias URLSessionResponse = (urlResponse: URLResponse?, data: Data?, error: Error?)

/// Encapsulate the result of the execution of an `HTTPRequestProtocol` conform object.
public struct HTTPRawResponse {
    
    // MARK: - Public Properties
    
    /// Executed request operation (weak referenced).
    public internal(set) weak var request: HTTPRequestProtocol?

    /// `URLResponse` object received from server.
    public let urlResponse: URLResponse?
    
    /// Casted `HTTPURLResponse` object received from server.
    public var httpResponse: HTTPURLResponse? {
        urlResponse as? HTTPURLResponse
    }
    
    /// Data received.
    public let data: Data?
    
    /// Error parsed.
    public internal(set) var error: HTTPError?
    
    /// Keep the `URLRequest` instance of the original
    public private(set) var urlRequest: (original: URLRequest?, current: URLRequest?)
    
    // MARK: - Initialization
    
    /// Initialize a new HTTPResponse object.
    ///
    /// - Parameters:
    ///   - request: request.
    ///   - urlRequest: url request.
    ///   - client: client source.
    ///   - response: response received from server.
    internal init(request: HTTPRequestProtocol, response: URLSessionResponse) {
        self.request = request
        self.urlResponse = response.urlResponse
        self.data = response.data
        self.error = HTTPError.fromURLResponse(response)
    }
    
    internal init(error type: HTTPError.ErrorType, forRequest request: HTTPRequestProtocol) {
        self.request = request
        self.error = HTTPError(type)
        self.urlResponse = nil
        self.data = nil
    }
    
    internal mutating func attachURLRequests(original: URLRequest?, current: URLRequest?) {
        self.urlRequest = (original, current)
    }
    
}
