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

// MARK: - HTTPRequestBuilderProtocol

/// This protocol is used to configure how the `URLRequest` is made when an `HTTPRequest` instance
/// must be executed in a `HTTPClient`.
/// Generally you should never need to intercept and modify this behaviour, but in case this is the
/// right way to accomplish it.
public protocol HTTPRequestBuilderProtocol {
    
    /// Create an `URLRequest` instance for a request when it runs on a `HTTPClient`.
    ///
    /// - Parameters:
    ///   - request: request to execute.
    ///   - client: destination client
    func urlRequest(for request: HTTPRequestProtocol, in client: HTTPClient) throws -> URLRequest
    
}

// MARK: - HTTPRequestBuilder

/// This is the default implementation used by the library in order to produce a valid `URLRequest`
/// to execute in a client instance.
open class HTTPRequestBuilder: HTTPRequestBuilderProtocol {
    
    open func urlRequest(for request: HTTPRequestProtocol, in client: HTTPClient) throws -> URLRequest {
        fatalError()
    }
    
    
}
