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

/// Encapsulate the result of the execution of an `HTTPRequestProtocol` conform object.
public struct HTTPRawResponse {
    
    // MARK: - Out (Public Properties)

    /// Response from server.
    public let response: URLResponse?
    
    /// Data received.
    public let data: Data?
    
    /// Error parsed.
    public let error: HTTPError?
    
    // MARK: - In (Public Properties)
    
    /// `URLRequest` executed.
    public let urlRequest: URLRequest
    
    /// Parent executed request.
    public internal(set) weak var request: HTTPRequestProtocol?
    
    /// Destinatin client where the request has been executed.
    public internal(set) var client: HTTPClient?
    
    // MARK: - Initialization
    
    /// Initialize a new HTTPResponse object.
    ///
    /// - Parameters:
    ///   - request: request.
    ///   - urlRequest: url request.
    ///   - client: client source.
    ///   - response: response received.
    ///   - data: data received.
    ///   - error: error parsed.
    internal init(request: HTTPRequestProtocol,
                urlRequest: URLRequest,
                client: HTTPClient,
                response: URLResponse?, data: Data?, error: Error?) {
        self.request = request
        self.urlRequest = urlRequest
        self.client = client
        self.response = response
        self.data = data
        self.error = HTTPError.fromHTTPResponse(response: response, data: data, error: error)
    }
    
}
