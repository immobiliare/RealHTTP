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
import Combine

/// Parameters for an `HTTPRequestProtocol`
public typealias HTTPParameters = [String: AnyObject]

/// Generic protocol which describe a request.
public protocol HTTPRequestProtocol {
    
    // MARK: - Public Properties
    
    /// Method to be used as request.
    var method: HTTPMethod { get set }
    
    /// Headers to send with the request. These values are combined with
    /// the default's `HTTPClient` used with the precedence on request's keys.
    var headers: HTTPHeaders { get set }
    
    /// parameters to encode onto the request.
    var parameters: HTTPParameters? { get set }
    
    /// Path to the endpoint. URL is composed along the `baseURL` of the `HTTPClient`
    /// instance where the request is running into.
    var route: String { get set }
    
    /// Timeout interval for request. When `nil` no timeout is set. This override the
    /// `HTTPClient` instance's `timeout`.
    var timeout: TimeInterval? { get set }
    
    /// Maximum number of retries to set.
    var maxRetries: Int { get set }
    
    /// This create the `URLRequest` instance for a request when running in a `HTTPClient` instance.
    /// You can setup your own object here to transform the request itself.
    /// By default the `HTTPRequestBuilder` is used.
    var requestBuilder: HTTPRequestBuilderProtocol { get set }
    
    // MARK: - Initialization
    
    /// Initialize a new request with given parameters.
    ///
    /// - Parameters:
    ///   - method: HTTP method for the request, by default is `.get`.
    ///   - route: route to compose with the base url of the `HTTPClient` where the request is running.
    init(method: HTTPMethod, route: String)
    
}

// MARK: - HTTPRequest

open class HTTPRequest<Object: HTTPDataDecodable, Err: Error>: HTTPRequestProtocol {
    
    // MARK: - Public Properties
    
    /// The object used to transform the request in a valid `URLRequest`.
    /// You can override it in case you need to make some special transforms.
    open var requestBuilder: HTTPRequestBuilderProtocol = HTTPRequestBuilder()
    
    /// Number of retries for this request. By default is set to `0` which means
    /// no retries are executed.
    open var maxRetries: Int = 0
    
    /// Timeout interval.
    open var timeout: TimeInterval?
    
    /// HTTP Method for request.
    open var method: HTTPMethod
    
    /// Headers to send along the request.
    open var headers = HTTPHeaders()
    
    /// Parameters for request.
    open var parameters: HTTPParameters?
    
    /// Route to the endpoint.
    open var route: String
    
    // MARK: - Initialization
    
    required public init(method: HTTPMethod, route: String) {
        self.method = method
        self.route = route
    }
    
    func run(in client: HTTPClient) -> AnyPublisher<Object, Err> {
        let urlRequest = try? requestBuilder.urlRequest(for: self, in: client)
        
        fatalError()
    }
    
}
