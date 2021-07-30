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


/// It's like `HTTPClient` but it maintain a queue of requests and
/// manage the maximum simultaneous requests you can execute
/// automatically.
/// You can use it when you need more control about the requests.
public class HTTPClientQueue: HTTPClient {
    
    // MARK: - Public Properties
    
    /// Maximum number of rimultaneous requests.
    public var maxSimultaneousRequest: Int
    
    // MARK: - Initialization
    
    public init(maxSimultaneousRequest: Int = 5,
                baseURL: String,
                configuration: URLSessionConfiguration = .default) {
        
        self.maxSimultaneousRequest = maxSimultaneousRequest
        super.init(baseURL: baseURL, configuration: configuration)
    }
}
