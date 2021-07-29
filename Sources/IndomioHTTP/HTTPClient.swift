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

public class HTTPClient {
    
    // MARK: - Public Properties
    
    /// Base URL.
    public let baseURL: String
    
    /// Service's URLSession instance to use.
    public var session: URLSession
    
    /// Headers which are part of each request made using the client.
    public var headers = HTTPHeaders.default
    
    /// Timeout interval for requests. Defaults to `60` seconds.
    /// Requests may override this behaviour.
    public var timeout: TimeInterval = 60
    
    /// The cache policy for the request. Defaults to `.useProtocolCachePolicy`.
    /// Requests may override this behaviour.
    public var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    
    // MARK: - Initialization
    
    /// Initialize a new HTTP client with given passed base URL.
    ///
    /// - Parameters:
    ///   - baseURL: base URL.
    ///   - session: session to use, by default is `.shared`.
    public init(baseURL: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    /// Initialize a new HTTP client with given `URLSessionConfiguration` instance.
    ///
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
    public convenience init(baseURL: String, configuration: URLSessionConfiguration) {
        let session = URLSession(configuration: configuration)
        self.init(baseURL: baseURL, session: session)
    }
    
}
