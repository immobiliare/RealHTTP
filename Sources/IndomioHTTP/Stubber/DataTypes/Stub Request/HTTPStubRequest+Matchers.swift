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

extension HTTPStubRequest {
    
    /// Configure the stub request to use a regular expression matcher to intercept URLs.
    ///
    /// - Parameters:
    ///   - pattern: pattern for validation.
    ///   - options: options for regular expression.
    /// - Returns: Self
    public func addURLMatch(regex pattern: String, options: NSRegularExpression.Options = []) -> Self {
        guard let matcher = HTTPStubRegExMatcher(regex: pattern, options: options, in: .url) else {
            return self
        }
        
        return match(matcher)
    }
    
    /// Configure the stub request to match the request's body with a configured `Codable` object.
    ///
    /// - Parameter object: object to match.
    /// - Returns: Self
    public func addJSONMatch<Object: Codable & Hashable>(_ object: Object) -> Self {
        let matcher = HTTPStubJSONMatcher(matchObject: object)
        return match(matcher)
    }
    
}
