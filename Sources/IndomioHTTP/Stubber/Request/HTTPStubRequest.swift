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

// MARK: - HTTPSubRequest Match Extensions

extension HTTPStubRequest {
    
    public func matchURL(regex pattern: String, options: NSRegularExpression.Options = []) -> Self {
        guard let matcher = HTTPStubRegExMatcher(regex: pattern, options: options, in: .url) else {
            return self
        }
        
        return match(matcher)
    }
    
}

// MARK: - HTTPSubRequest Stub Extensions

extension HTTPStubRequest {
    
    /// Add stub response for specified http method with a json raw string.
    /// Content type is set to `.json` automatically.
    ///
    /// - Parameters:
    ///   - method: the http method which trigger this stubbed response.
    ///   - code: code to use, by default is `ok` (200).
    ///   - string: raw json string to include.
    /// - Returns: Self
    public func stub(_ method: HTTPMethod, code: HTTPStatusCode = .ok, delay: TimeInterval? = nil,
                     json string: String) -> Self {
        let response = HTTPStubResponse()
        response.contentType = .jsonWithCharset
        response.statusCode = .ok
        response.body = string
        response.responseDelay = delay
        responses[method] = response
        return self
    }
    
//    public func stub(_ method: HTTPMethod, code: HTTPStatusCode = .ok, json fileURL: URL) -> Self {
//        guard fileURL.isFileURL, FileManager.default.fileExists(atPath: fileURL.path) else {
//            fatalError("Required file for stub does not exist")
//        }
//
//        var response = HTTPStubResponse().
//    }
    
}
