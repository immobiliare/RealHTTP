//
//  IndomioHTTP
//
//  Created by the Mobile Team @ ImmobiliareLabs
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Copyright ©2021 Immobiliare.it SpA. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

// MARK: - HTTPSubRequest

public class HTTPStubRequest: Equatable {
    
    // MARK: - Public Properties
    
    /// Matching options for request.
    ///
    /// NOTE:
    /// Matchers are evaluted in AND, so all matchers must be valid in order to make the stub valid for a request.
    public var matchers = [HTTPStubMatcherProtocol]()
        
    /// Response to produce for each http method which match this request.
    public var responses = [HTTPMethod: HTTPStubResponse]()
        
    // MARK: - Initialization
    
    public init() {}
        
    public static func == (lhs: HTTPStubRequest, rhs: HTTPStubRequest) -> Bool {
        false
    }
    
    // MARK: - Private Functions
    
    internal func suitableFor(_ urlRequest: URLRequest) -> Bool {
        for matcher in matchers {
            if matcher.matches(request: urlRequest, for: self) == false {
                return false
            }
        }
        
        return true
    }
    
}
