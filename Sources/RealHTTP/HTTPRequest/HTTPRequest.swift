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

public class HTTPRequest<Value: HTTPDecodableResponse>: Equatable, Hashable {
    
    // MARK: - Public Properties
    
    /// An user info dictionary where you can add your own data.
    /// Initially only the `fingerprint` key is set with an unique id of the request.
    public var userInfo: [AnyHashable : Any] = [
        UserInfoKeys.fingerprint: UUID().uuidString
    ]
    
    /// Route to the endpoint.
    open var route: String
    
    /// Timeout interval.
    ///
    /// NOTE:
    /// When not specified the HTTPClient's value where the request is executed is used.
    open var timeout: TimeInterval?
    
    /// HTTP Method for request.
    open var method: HTTPMethod

    /// Headers to send along the request.
    ///
    /// NOTE:
    /// Values here are combined with HTTPClient's values where the request is executed
    /// with precedence for request's keys.
    open var headers = HTTPHeaders()
    
    /// Cache policy.
    ///
    /// NOTE:
    /// When not specified the HTTPClient's value where the request is executed is used.
    open var cachePolicy: URLRequest.CachePolicy?
    
    /// The HTTP Protocol version to use for request.
    open var httpVersion: HTTPVersion = .default
    
    /// Number of retries for this request.
    /// By default is set to `0` which means no retries are executed.
    open var maxRetries: Int = 0
    
    // MARK: - Initialization
    
    /// Initialize a new request.
    ///
    /// - Parameters:
    ///   - method: method for http.
    ///   - route: route name.
    required
    public init(_ method: HTTPMethod = .get, route: String = "") {
        self.method = method
        self.route = route
    }
}

// MARK: - Configuration Pattern

extension HTTPRequest {
    
    public func configure(with block: (inout Self) throws -> Void) rethrows -> Self {
        var copy = self
        try block(&copy)
        return copy
    }
    
    public func configure(with block: (inout Self) -> Void) -> Self {
        var copy = self
        block(&copy)
        return copy
    }
    
}
