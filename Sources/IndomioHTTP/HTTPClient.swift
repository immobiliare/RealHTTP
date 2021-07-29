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
    
    /// Timeout interval for requests. Value can be overriden if `nil`.
    public var timeout: TimeInterval?
    
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
    /// - Parameters:
    ///   - baseURL: base URL.
    ///   - configuration: `URLSession` configuration.
    public convenience init(baseURL: String, configuration: URLSessionConfiguration) {
        let session = URLSession(configuration: configuration)
        self.init(baseURL: baseURL, session: session)
    }
    
}
