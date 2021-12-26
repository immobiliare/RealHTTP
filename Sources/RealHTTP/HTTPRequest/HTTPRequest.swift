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

public typealias HTTPRequestParametersDict = [String: Any]

public class HTTPRequest<Value: HTTPDecodableResponse>: HTTPRequestProtocol {
    
    // MARK: - Public Properties
    
    /// An user info dictionary where you can add your own data.
    /// Initially only the `fingerprint` key is set with an unique id of the request.
    public var userInfo: [AnyHashable : Any] = [
        UserInfoKeys.fingerprint: UUID().uuidString
    ]
    
    /// Timeout interval.
    ///
    /// NOTE:
    /// When not specified the HTTPClient's value where the request is executed is used.
    open var timeout: TimeInterval?
    
    /// HTTP Method for request.
    open var method: HTTPMethod = .get
    
    /// Full URL.
    ///
    /// NOTE:
    /// If you specify a relative path and you need the destination HTTPClient instance
    /// to get the full URL, this value maybe wrong.
    public var url: URL? {
        urlComponents.url
    }

    /// Headers to send along the request.
    ///
    /// NOTE:
    /// Values here are combined with HTTPClient's values where the request is executed
    /// with precedence for request's keys.
    open var headers: HTTPHeaders {
        get { body.headers }
        set { body.headers = newValue }
    }
    
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
    
    /// Security settings.
    open var security: HTTPSecurityProtocol?
    
    /// Request's body.
    open var body: HTTPBody = .empty
    
    // MARK: - Private Properties
    
    private var urlComponents = URLComponents()
    
    // MARK: - Initialization
    
    /// Initialize a new request.
    ///
    /// - Parameters:
    ///   - url: full URL if applicable.
    ///   - configure: configure callback.
    public init(url: URLConvertible? = nil, _ configure: (inout HTTPRequest<Value>) throws -> Void) rethrows {
        var this = self
        try configure(&this)
        
        if let url = url,
           let components = try? URLComponents(url: url.asURL(), resolvingAgainstBaseURL: false) {
            self.urlComponents = components
        }
    }
    
}

// MARK: - HTTPRequest + URL Builder Extension

extension HTTPRequest {
    
    /// Set the URI Schema of the url.
    /// Use it if you need to set an absolute URL and you don't need to inerith this value from
    /// destination `HTTPClient` instance.
    public var scheme: URIScheme {
        get { urlComponents.scheme.map(URIScheme.init(rawValue:)) ?? .https }
        set { urlComponents.scheme = newValue.rawValue }
    }
    
    /// Set an absolute host of the url.
    /// When not nil it will override the destination `HTTPClient`'s `host` parameter.
    public var host: String? {
        get { urlComponents.host }
        set { urlComponents.host = newValue }
    }
    
    /// Set the path component of the URL.
    public var path: String {
        get { urlComponents.path }
        set { urlComponents.path = newValue }
    }
    
    /// Setup a list of query string parameters.
    public var query: [URLQueryItem]? {
        get { urlComponents.queryItems }
        set { urlComponents.queryItems = newValue }
    }
    
    /// Set the port of the request. If not set the default HTTP port is used.
    public var port: Int? {
        get { urlComponents.port }
        set { urlComponents.port = newValue }
    }
    
    /// Add a new query parameter to the query string's value.
    ///
    /// - Parameters:
    ///   - name: name of the parameter to add.
    ///   - value: value of the parameter to add.
    public func addQueryParameter(name: String, value: String) {
        let item = URLQueryItem(name: name, value: value)
        add(queryItem: item)
    }
    
    /// Add a new query parameter via `URLQueryItem` instance.
    ///
    /// - Parameter item: instance of the query item to add.
    public func add(queryItem item: URLQueryItem) {
        if query != nil {
            query?.append(item)
        } else {
            query = [item]
        }
    }
    
}
