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
    open var contentType: HTTPContentType?
    
    /// Once set this value is returned instead of the data set.
    open var failError: Error?
    
    /// Contains a map of the data to return.
    open var body: HTTPStubDataConvertible? {
        didSet {
            self.dataSize = body?.data?.count ?? 0
        }
    }
        
    /// The size of the fake response body, in bytes.
    public private(set) var dataSize: Int = 0
    
    /// The headers to send back with the response.
    open var headers =  HTTPHeaders()
    
    /// Allow response caching. Usually you dont want to have a cached response
    /// so the default behaviour is set to `notAllowed`.
    open var cachePolicy: URLCache.StoragePolicy = .notAllowed
    
    /// You can define a delay to return the reponse.
    /// You can use it to simulate network speed.
    /// By default `immediate` is used.
    open var responseTime: HTTPStubResponseInterval = .immediate
    
    /// Stubber will wait `requestTime` before sending the `NSHTTPURLResponse` headers.
    /// You can use it to simulate a slow network.
    open var requestTime: TimeInterval?
    
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

// MARK: - HTTPStubResponseInterval

/// Define the response interval for a stubbed request:
/// - `immediate`: return an immediate response with no delay
/// - `delayedBy`: return a response after a certain delay interval in seconds
/// - `withSpeed`: return a response by simulating a connection quality.
public enum HTTPStubResponseInterval {
    case immediate
    case delayedBy(TimeInterval)
    case withSpeed(HTTPConnectionSpeed)
}

// MARK: - HTTPConnectionSpeed

/// Simulate a connection speed.
public enum HTTPConnectionSpeed {
    case speed1kbps
    case speedSlow
    case speedGPRS
    case speedEdge
    case speed3G
    case speed3GPlus
    case speedWiFi
    
    /// kbps -> KB/s
    internal var value: Double {
        switch self {
        case .speed1kbps:   return 8/8
        case .speedSlow:    return 12/8
        case .speedGPRS:    return 56/8
        case .speedEdge:    return 128/8
        case .speed3G:      return 3200/8
        case .speed3GPlus:  return 7200/8
        case .speedWiFi:    return 12000/8
        }
    }
}
