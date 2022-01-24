//
//  RealHTTP
//  Lightweight Async/Await Network Layer/Stubber for Swift
//
//  Created & Maintained by Mobile Platforms Team @ ImmobiliareLabs.it
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Authors:
//   - Daniele Margutti <hello@danielemargutti.com>
//
//  Copyright ©2022 Immobiliare.it SpA.
//  Licensed under MIT License.
//

import Foundation

public class HTTPRequest {
    public typealias RequestTask = Task<HTTPResponse, Error>
    
    // MARK: - Supported Structures
    
    internal static let DefaultTimeout = TimeInterval(10)
    
    /// A set of common keys you can use to fill the `userInfo` keys of your request.
    public enum UserInfoKeys: Hashable {
        case fingerprint
        case subsystem
        case category
        case data
    }
    
    // MARK: - Public Properties
    
    /// Priority level in which the task is executed.
    /// 
    /// By default is set to `background`.
    public var priority: TaskPriority = .background
    
    /// Session task currently in execution.
    public internal(set) weak var sessionTask: URLSessionTask?
    
    /// Client in which the task is running.
    public internal(set) weak var client: HTTPClient?
    
    /// An user info dictionary where you can add your own data.
    /// Initially only the `fingerprint` key is set with an unique id of the request.
    public var userInfo: [AnyHashable : Any] = [
        UserInfoKeys.fingerprint: UUID().uuidString
    ]
    
    /// This property will be automatically read by the library. If not nil it
    /// will be used to attempt to resume the request's download.
    /// It works only when `transferMode = .largeData`.
    ///
    /// The data you pass here can come from 2 cases:
    ///
    /// 1. EXTERNAL CAUSE
    /// Your connection has dropped, timeout or something not related to the user interaction:
    /// You should monitor `progress` variable in order to catch the `failed` event.
    ///
    /// ```swift
    /// request.$progress.sink { progress in
    ///        if progress?.event == .failed, let partialData = progress?.partialData {
    ///             // save it somewhere or assign directly to a new request's `.partialData`
    ///        }
    /// }.store(in: &observerBag)
    /// ```
    ///
    /// Now you just assign `.partialData` to the value you get and restart your download.
    ///
    /// 2. CANCELLED TASK
    /// You can cancel a running task using `cancel(byProducingResumeData:)` in order to
    /// get a resumable data to use in a new request's as `.partialData`.
    public var partialData: Data?
    
    /// Timeout interval.
    ///
    /// NOTE:
    /// When not specified the HTTPClient's value where the request is executed is used.
    public var timeout: TimeInterval?
    
    /// HTTP Method for request, by default `get`.
    public var method: HTTPMethod = .get
    
    /// Set the full absolute URL for the request by ignoring the the url components
    /// and the `baseURL` of the destination client.
    ///
    /// NOTE:
    /// When you specify a full URL via this set don't use the `port`, `scheme`, `host` after.
    /// If you are specifying an IP address (ex. `127.0.0.1:8080`) remember to add the scheme prefix.
    public var url: URL? {
        get {
            urlComponents.url
        }
        set {
            if let url = newValue,
                let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                urlComponents = components
            }
        }
    }
    
    /// Headers to send along the request.
    ///
    /// NOTE:
    /// Values here are combined with HTTPClient's values where the request is executed
    /// with precedence for request's keys.
    public var headers: HTTPHeaders {
        get { body.headers }
        set { body.headers = newValue }
    }
    
    /// What kind of data we should expect.
    /// If you are creating a request for a small amount of data (ie RESTful calls) you can use `default`.
    /// Large data as binary downloads may be handled using `large` options which support
    /// resumable downloads and background downloads sessions.
    ///
    /// By default `default` is used.
    public var transferMode: HTTPTransferMode = .default
    
    /// Cache policy.
    ///
    /// NOTE:
    /// When not specified the HTTPClient's value where the request is executed is used.
    public var cachePolicy: URLRequest.CachePolicy?
    
    /// The HTTP Protocol version to use for request.
    public var httpVersion: HTTPVersion = .default
    
    /// Describe the priority of the operation.
    /// It may acts as a suggestion for HTTP/2 based services (priority frames / dependency weighting)
    /// for simple `HTTPClient` instances.
    public var httpPriority: HTTPRequestPriority = .normal
    
    /// Number of retries for this request.
    /// By default is set to `0` which means no retries are executed.
    public var maxRetries: Int = 0
    
    /// Security settings.
    public var security: HTTPSecurity?
    
    /// Request's body.
    public var body: HTTPBody = .empty
    
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
    
    /// Current network attempt. Use `maxRetries` to set the number of attempts
    /// per each request.
    internal var currentRetry = 0
    
    /// Alternate requests cannot support retry strategy,
    /// this property is automatically set by the client's loader
    /// to avoid recursive check.
    internal var isAltRequest = false
    
    /// URLComponents of the network request.
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
    
    // MARK: - Fetch Operations
    
    /// Fetch data asynchronously and return the raw response.
    ///
    /// - Parameter client: client where execute the request.
    /// - Returns: `HTTPResponse`
    public func fetch(_ client: HTTPClient = .shared) async throws -> HTTPResponse {
        try await client.fetch(self)
    }
    
    /// Fetch data asynchronously and return decoded object with given passed type.
    /// Object must be conform to `HTTPDecodableResponse` if you want to implement custom decode.
    ///
    /// - Returns: T?
    public func fetch<T: HTTPDecodableResponse>(_ client: HTTPClient = .shared,
                                                decode: T.Type) async throws -> T? {
        try await client.fetch(self).decode(decode)
    }
    
    /// Fetch data asynchronously and return the decoded object by using `Decodable` conform type.
    ///
    /// - Returns: T?
    public func fetch<T: Decodable>(_ client: HTTPClient = .shared,
                                    decode: T.Type, decoder: JSONDecoder = .init()) async throws -> T? {
        try await client.fetch(self).decode(decode)
    }
    
    // MARK: - Task Management
    
    /// Cancel request if it's running.
    ///
    /// - Parameter byProducingResumeData: only when `transferMode = .largeData` you can choose to produce resumable data and handle it in this callback.
    /// - Returns: Bool
    @discardableResult
    public func cancel(byProducingResumeData: ((Data?) -> Void)?) -> Bool {
        if transferMode == .largeData {
            if let dataProducer = byProducingResumeData {
                (sessionTask as? URLSessionDownloadTask)?.cancel(byProducingResumeData: dataProducer)
            } else {
                sessionTask?.cancel()
            }
        } else {
            sessionTask?.cancel()
        }
        
        return sessionTask != nil
    }
    
    // MARK: - Public Functions
    
    /// Set cookies for a given request.
    ///
    /// NOTES:
    /// 1. When you set this cookie values are automatically to a `Cookie` header
    ///    and attached to the `headers` properties, eventually replacing existing `Cookie` node.
    ///    If you want to set a shared cookies consider using the `HTTPCookieStorage` attached
    ///    to each destination `HTTPClient` instance.
    ///
    /// 2. Each new get call to cookies produce new instances of `HTTPCookie` even with the same values
    ///    (this because value is parsed on the fly from `headers` properties).
    public func setCookies(_ cookies: [HTTPCookie]) {
        let headerFields = HTTPCookie.requestHeaderFields(with: cookies).map { item in
            HTTPHeaders.Element(name: item.key, value: item.value)
        }
        headers.set(headerFields)
    }
    
}

// MARK: - HTTPRequest + URL Builder Extension

public extension HTTPRequest {
    
    /// Set the URI Schema of the url.
    /// Use it if you need to set an absolute URL and you don't need to inerith this value from
    /// destination `HTTPClient` instance.
    var scheme: HTTPScheme {
        get { urlComponents.scheme.map(HTTPScheme.init(rawValue:)) ?? .https }
        set { urlComponents.scheme = newValue.rawValue }
    }
    
    /// Set an absolute host of the url.
    /// When not nil it will override the destination `HTTPClient`'s `host` parameter.
    var host: String? {
        get { urlComponents.host }
        set { urlComponents.host = newValue }
    }
    
    /// Set the path component of the URL.
    ///
    /// NOTE:
    /// If you pass a full URL it will replace any existing set for scheme, host, and port.
    var path: String {
        get { urlComponents.path }
        set {
            if newValue.isAbsoluteURL, let parsed = URLComponents(string: newValue) {
                // An absolute URL will replace any settings from destination client.
                urlComponents = parsed
            } else {
                if newValue.first == "/" {
                    urlComponents.path = newValue
                } else {
                    urlComponents.path = "/\(newValue)"
                }
            }
        }
    }
    
    /// Setup a list of query string parameters.
    var query: [URLQueryItem]? {
        get { urlComponents.queryItems }
        set { urlComponents.queryItems = newValue }
    }
    
    /// Set the port of the request. If not set the default HTTP port is used.
    var port: Int? {
        get { urlComponents.port }
        set { urlComponents.port = newValue }
    }
    
    /// Add a new query parameter to the query string's value.
    ///
    /// - Parameters:
    ///   - name: name of the parameter to add.
    ///   - value: value of the parameter to add.
    func addQueryParameter(name: String, value: String) {
        let item = URLQueryItem(name: name, value: value)
        add(queryItem: item)
    }
    
    /// Add a new query parameter via `URLQueryItem` instance.
    ///
    /// - Parameter item: instance of the query item to add.
    func add(queryItem item: URLQueryItem) {
        if query != nil {
            query?.append(item)
        } else {
            query = [item]
        }
    }
    
    /// Add an array of query params.
    ///
    /// - Parameter queryItems: query items to add.
    func add(queryItems: [URLQueryItem]) {
        queryItems.forEach {
            add(queryItem: $0)
        }
    }
    
    /// Add query items from a passed dictionary of elements.
    ///
    /// - Parameter parameters: parameters dictionary.
    func add(parameters: [String: String]) {
        parameters.forEach { item in
            add(queryItem: URLQueryItem(name: item.key, value: item.value))
        }
    }
    
}

// MARK: - URLRequest and URLSessionTask Builders

extension HTTPRequest {
    
    // MARK: - Internal Functions
    
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
                if let partialData = partialData {
                    task = client.session.downloadTask(withResumeData: partialData)
                } else {
                    task = client.session.downloadTask(with: urlRequest)
                }
            }
        }
        
        /// Keep in mind it's just a suggestion for HTTP/2 based services.
        task.priority = httpPriority.urlTaskPriority
        return task
    }
        
    /// Create the `URLRequest` instance for a client instance.
    ///
    /// - Parameter client: client instance.
    /// - Returns: `URLRequest`
    internal func urlRequest(inClient client: HTTPClient) throws -> URLRequest {
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
        urlRequest.httpShouldHandleCookies = true
        try urlRequest.setHTTPBody(body) // setup the body
        return urlRequest
    }
    
}

extension URLComponents {
    
    mutating func fullURLInClient(_ client: HTTPClient?) -> URL? {
        guard host == nil else {
            return self.url
        }
        
        guard let baseURL = client?.baseURL else { return nil }
        // If we have not specified an absolute URL the URL
        // must be composed using the base components of the set client.
        var newComp = self
        newComp.scheme = baseURL.scheme
        newComp.host = baseURL.host
        newComp.port = baseURL.port
        newComp.path = baseURL.path + newComp.path
        return newComp.url
    }
    
}
