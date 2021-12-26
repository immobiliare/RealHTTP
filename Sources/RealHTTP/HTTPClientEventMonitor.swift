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

public class HTTPClientEventMonitor: NSObject {
    
    // MARK: - Public Properties
    
    public internal(set) weak var client: HTTPClient?
    
    // MARK: - Internal Properties
    
    internal var session: URLSessionConfiguration
    
    /// The cache policy for the request. Defaults to `.useProtocolCachePolicy`.
    /// Requests may override this behaviour.
    internal var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    
    internal init(session: URLSessionConfiguration) {
        self.session = session
    }
    
}
