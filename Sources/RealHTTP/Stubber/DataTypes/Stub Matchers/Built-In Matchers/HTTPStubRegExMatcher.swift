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

public class HTTPStubRegExMatcher: HTTPStubMatcher {
    
    // MARK: - Public Properties
    
    /// Regular expression to validate.
    public var regex: NSRegularExpression
    
    /// Encoding used to decode body's data when used.
    /// By default is `.utf8`.
    public var encoding: String.Encoding = .utf8
    
    /// Where to validate the regular expression.
    public var location: HTTPMatcherLocation

    // MARK: - Initialization
    
    /// Initialize a new regular expression matcher.
    ///
    /// - Parameters:
    ///   - pattern: regex pattern to validate.
    ///   - options: options for regular expression matching.
    ///   - location: where to validate the regular expression.
    public init(regex pattern: String, options: NSRegularExpression.Options = [], in location: HTTPMatcherLocation) throws {
        self.regex = try NSRegularExpression(pattern: pattern, options: options)
        self.location = location
    }
    
    // MARK: - Conformances
    
    public func matches(request: URLRequest, for source: HTTPMatcherSource) -> Bool {
        switch location {
        case .url:
            return regex.hasMatches(request.url?.absoluteString)
        
        case .body:
            let bodyAsString = request.body?.asString(encoding: encoding)
            return regex.hasMatches(bodyAsString)
            
        case .headersValue,
             .headersKey:
            guard let headers = request.allHTTPHeaderFields else {
                return false
            }
            
            // swiftlint:disable unused_enumerated
            for (_, element) in headers.enumerated() {
                let valueToCheck = (location == .headersKey ? element.key : element.value)
                return regex.hasMatches(valueToCheck)
            }
            
            return false
        }
    }
    
}
