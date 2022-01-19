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
//  Copyright ©2021 Immobiliare.it SpA.
//  Licensed under MIT License.
//

import Foundation

/// HTTPClient is the place where each request will be executed.
/// It contains the complete configuration, keep cookies and sessions.
public class HTTPClient {
    
    // MARK: - Public Properties
    
    /// Shared HTTPClient instance.
    public static let shared = HTTPClient(baseURL: nil)
    
    /// Base URL used to compose each request.
    ///
    /// NOTE:
    /// If request is executed by passing a complete URL with scheme this
    /// value will be automatically ignored.
    public var baseURL: URL?
    
    /// URLSessionConfigurastion used to perform request in this client.
    public var session: URLSession {
        loader.session
    }
    
    /// The cache policy for the request. Defaults to `.useProtocolCachePolicy`.
    /// Requests may override this behaviour.
    public var cachePolicy: URLRequest.CachePolicy {
        get { loader.cachePolicy }
        set { loader.cachePolicy = newValue }
    }
    
    /// Headers which are automatically attached to each request.
    public var headers = HTTPHeaders()
    
    /// Timeout interval for requests, expressed in seconds.
    /// Defaults value is `HTTPRequest.DefaultTimeout` but each http request may use it's value.
    public var timeout: TimeInterval = HTTPRequest.DefaultTimeout
    
    /// Security settings.
    public var security: HTTPSecurity?
    
    /// Cookies storage.
    public var cookies: HTTPCookieStorage? {
        loader.session.configuration.httpCookieStorage
    }
    
    /// Follow or not redirects. By default the value is `follow` which uses
    /// the new proposed redirection by copying the original HTTPMethod, Body and Headers.
    ///
    /// You can further customize and alter the behaviour per single request by implementing
    /// the `HTTPClientDelegate`'s `client(:willPerformRedirect:response:newRequest:)`
    /// function.
    public var followRedirectsMode: HTTPRedirectFollow = .follow
    
    /// Validators for response. Values are executed in order.
    public var validators: [HTTPResponseValidator] = [
        HTTPDefaultValidator() // standard validator for http responses
    ]
    
    // MARK: - Private Properties
    
    /// Event monitor used to execute http requests.
    private var loader: HTTPDataLoader
    
    // MARK: - Initialization
    
    /// Initialize a new HTTP Client instance with a given configuration.
    ///
    /// - Parameters:
    ///   - baseURL: base URL. You can also pass a valid URL as `String`.
    ///   - maxConcurrentOperations: the number of concurrent network operation we can execute. If not specified is managed
    ///                              by the operation system and you don't need to set a value unless you have some other constraints.
    ///   - configuration: `URLSession` configuration. The available types are `default`,
    ///                    `ephemeral` and `background`, if you don't provide any or don't have
    ///                     special needs then Default will be used.
    ///
    ///                     - `default`: uses a persistent disk-based cache (except when the result is downloaded to a file)
    ///                     and stores credentials in the user’s keychain.
    ///                     It also stores cookies (by default) in the same shared cookie store as the
    ///                     NSURLConnection and NSURLDownload classes.
    ///                     - `ephemeral`: similar to a default session configuration object except that
    ///                     the corresponding session object does not store caches,
    ///                     credential stores, or any session-related data to disk. Instead,
    ///                     session-related data is stored in RAM.
    ///                     - `background`: suitable for transferring data files while the app runs in the background.
    ///                     A session configured with this object hands control of the transfers over to the system,
    ///                     which handles the transfers in a separate process.
    ///                     In iOS, this configuration makes it possible for transfers to continue even when
    ///                     the app itself is suspended or terminated.
    public init(baseURL: URL?,
                maxConcurrentOperations: Int? = nil,
                configuration: URLSessionConfiguration = .default) {
        
        self.baseURL = baseURL
        self.loader = HTTPDataLoader(configuration: configuration,
                                     maxConcurrentOperations: maxConcurrentOperations ?? OperationQueue.defaultMaxConcurrentOperationCount)
        self.loader.client = self
    }
    
    // MARK: - Internal Functions
    
    /// Execute the request and return the promise.
    ///
    /// - Parameter request: request to execute in client.
    /// - Returns: `HTTPRequest.RequestTask?`
    internal func fetch(_ request: HTTPRequest) async throws -> HTTPResponse {
        try await loader.fetch(request)
    }
    
    /// Validate the response using the ordered list of validators.
    ///
    /// - Parameters:
    ///   - response: response received from server.
    ///   - request: origin request.
    /// - Returns: HTTPResponseValidatorAction
    internal func validate(response: HTTPResponse, forRequest request: HTTPRequest) -> HTTPResponseValidatorResult {
        for validator in validators {
            let result = validator.validate(response: response, forRequest: request)
            guard case .success = result else {
                return result
            }
        }
        
        return .success
    }
    
}
