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

public class HTTPRequest {
    public typealias RequestTask = Task<HTTPResponse, Error>
    
    internal static let DefaultTimeout = TimeInterval(10)
    
    // MARK: - Public Properties
    
    /// Priority level in which the task is executed.
    /// By default is set to `background`.
    public var priority: TaskPriority = .background
    
    /// Describe the priority of the operation.
    /// It may acts as a suggestion for HTTP/2 based services (priority frames / dependency weighting)
    /// for simple `HTTPClient` instances.
    /// In case of `HTTPQueueClient` it also act as priority level for queue concurrency.
    public var httpPriority: HTTPRequestPriority = .normal
    
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
    
    /// What kind of data we should expect.
    /// If you are creating a request for a small amount of data (ie RESTful calls) you can use
    /// `default`. Large data as binary downloads may be handled using `large` options which support
    /// resumable downloads and background downloads sessions.
    /// By default `default` is used.
    open var transferMode: HTTPTransferMode = .default
    
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
    
    // MARK: - Public Properties [Response]
    
    /// If task is monitorable (`expectedDataType` is `large`) and data is available
    /// here you can found the latest progress stats.
    #if canImport(Combine)
    @Published
    public internal(set) var progress: HTTPProgress?
    #else
    public internal(set) var progress: HTTPProgress?
    #endif
    
    // MARK: - Private Properties
    
    internal var urlComponents = URLComponents()
    
    // MARK: - Initialization
    
    /// Initialize a new request.
    ///
    /// - Parameters:
    ///   - url: full URL if applicable.
    ///   - configure: configure callback.
    public init(url: URLConvertible? = nil,
                _ configure: (inout HTTPRequest) throws -> Void) rethrows {
        var this = self
        try configure(&this)
        
        if let url = url,
           let components = try? URLComponents(url: url.asURL(), resolvingAgainstBaseURL: false) {
            self.urlComponents = components
        }
    }
    
    /// Initialize a new request with given URI template for path component.
    ///
    /// - Parameters:
    ///   - template: template.
    ///   - variables: variables to expand.
    ///   - configure: configure callback.
    public convenience init(URI template: String, variables: [String: Any],
                _ configure: (inout HTTPRequest) throws -> Void) rethrows {
        let path = URITemplate(template: template).expand(variables)
        try self.init(url: nil, configure)
        self.path = path
    }
    
    public func fetch(_ client: HTTPClient = .shared) async throws -> HTTPResponse {
        try await client.fetch(self)
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

extension URLComponents {
    
    mutating func fullURLInClient(_ client: HTTPClient?) -> URL? {
        // Path must start with "/" in order to generate a valid url.
        // We want to "fix" it automatically if we can.
        if !path.isEmpty, path.first != "/" { path = "/\(path)" }
        
        // If we have not specified an absolute URL the URL
        // must be composed using the base components of the set client.
        return (host == nil ? url(relativeTo: client?.baseURL) : url)
    }
    
}
