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

public class HTTPStubRequest: Equatable {
    
    // MARK: - Public Properties
    
    /// Matching options for request.
    public var matchers = [HTTPStubMatcher]()
    
    /// Response to produce for each http method which match this request.
    public var responses = [HTTPMethod: HTTPStubResponse]()
        
    // MARK: - Initialization
    
    public init() {
    }

    public func stub(_ method: HTTPMethod, _ response: HTTPStubResponse) -> Self {
        responses[method] = response
        return self
    }
    
    public func match(_ matcher: HTTPStubMatcher) -> Self {
        matchers.append(matcher)
        return self
    }
    
    public static func == (lhs: HTTPStubRequest, rhs: HTTPStubRequest) -> Bool {
        false
    }
    
    internal func suitableFor(_ urlRequest: URLRequest) -> Bool {
        for matcher in matchers {
            if matcher.matches(request: urlRequest, forStub: self) == false {
                return false
            }
        }
        
        return true
    }
    
}

extension HTTPStubRequest {
    
    public func matchURL(regex pattern: String, options: NSRegularExpression.Options = []) -> Self {
        guard let matcher = HTTPStubRegExMatcher(regex: pattern, options: options, in: .url) else {
            return self
        }
        
        return match(matcher)
    }
    
    public func stub(_ method: HTTPMethod, json string: String) -> Self {
        var response = HTTPStubResponse()
        response.contentType = .jsonWithCharset
        response.statusCode = .ok
        response.body = string
        responses[method] = response
        return self
    }
    
}
