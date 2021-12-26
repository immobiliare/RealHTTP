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

/// HTTPClient is the place where each request will be executed.
/// It contains the complete configuration, keep cookies and sessions.
public class HTTPClient {
    
    // MARK: - Public Properties
    
    /// Shared HTTPClient instance.
    public static let shared = HTTPClient()
    
    /// Base URL used to compose each request.
    ///
    /// NOTE:
    /// If request is executed by passing a complete URL with scheme this
    /// value will be automatically ignored.
    public let baseURL: String
    
    /// URLSessionConfigurastion used to perform request in this client.
    public var session: URLSessionConfiguration {
        get { eventMonitor.session }
        set { eventMonitor.session = newValue }
    }
    
    /// The cache policy for the request. Defaults to `.useProtocolCachePolicy`.
    /// Requests may override this behaviour.
    public var cachePolicy: URLRequest.CachePolicy {
        get { eventMonitor.cachePolicy }
        set { eventMonitor.cachePolicy = newValue }
    }
    
    /// Timeout interval for requests, expressed in seconds.
    /// Defaults value is `30` seconds but each http request may use it's value.
    public var timeout: TimeInterval = 30
    
    /// Event monitor used to execute http requests.
    public let eventMonitor: HTTPClientEventMonitor
    
    // MARK: - Private Properties
    
    // MARK: - Initialization
    
    /// Initialize a new HTTP Client instance with a given configuration.
    ///
    /// - Parameters:
    ///   - baseURL: base URL.
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
    public init(baseURL: String = "", configuration: URLSessionConfiguration = .default) {
        self.baseURL = baseURL
        self.eventMonitor = HTTPClientEventMonitor(session: configuration)
        self.eventMonitor.client = self
    }
    
    // MARK: - Public Functions
    
    @discardableResult
    public func execute(request: HTTPRequestProtocol) async -> HTTPRequestProtocol {
        fatalError()
    }
    
}
