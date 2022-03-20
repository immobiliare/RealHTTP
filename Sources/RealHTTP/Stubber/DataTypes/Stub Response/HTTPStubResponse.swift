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

open class HTTPStubResponse {
    
    /// The HTTP status code to return with the response.
    open var statusCode: HTTPStatusCode = .none
    
    /// Content type of the response.
    open var contentType: HTTPContentType? = nil
    
    /// Once set this value is returned instead of the data set.
    open var failError: Error? = nil
    
    /// Contains a map of the data to return.
    open var body: HTTPStubDataConvertible? = nil
    
    /// The headers to send back with the response.
    open var headers =  HTTPHeaders()
    
    /// Allow response caching. Usually you dont want to have a cached response
    /// so the default behaviour is set to `notAllowed`.
    open var cachePolicy: URLCache.StoragePolicy = .notAllowed
    
    /// You can define a delay to return the reponse.
    /// If `nil` no delay is applied.
    open var responseDelay: TimeInterval? = nil

    /// public initializer to make it available from outside
    public init() {

    }
    
    // MARK: - Internal Functions
    
    /// You can use it to adapt the stub response for a particular request.
    ///
    /// - Parameter request: request.
    /// - Returns: `HTTPStubResponse`
    open func adaptForRequest(_ request: URLRequest) -> HTTPStubResponse {
        self
    }
    
}
