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

internal class HTTPClientEventMonitor: NSObject {
    
    // MARK: - Public Properties
    
    internal weak var client: HTTPClient?
    
    /// Request internal queue.
    private var requestsQueue = [HTTPRequest]()
    
    private lazy var requestsStream: AsyncStream<HTTPRequest> = {
        AsyncStream { continuation in
            
        }
    }()
    
    internal var maximumNumberOfRequests: UInt = 0
    
    // MARK: - Internal Properties
    
    internal var session: URLSessionConfiguration
    
    /// The cache policy for the request. Defaults to `.useProtocolCachePolicy`.
    /// Requests may override this behaviour.
    internal var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    
    internal init(session: URLSessionConfiguration) {
        self.session = session
    }
    
    internal func add(request: HTTPRequest) async throws -> HTTPResponse {

    }
    
}
