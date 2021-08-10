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

public class HTTPStubRegExMatcher: HTTPStubMatcher {
    
    
    /// Regular expression to validate.
    public var regex: NSRegularExpression
    
    public var location: HTTPMatcherLocation

    // MARK: - Initialization
    
    public init?(regex pattern: String, options: NSRegularExpression.Options = [], in location: HTTPMatcherLocation) {
        do {
            self.regex = try NSRegularExpression(pattern: pattern, options: options)
            self.location = location
        } catch {
            return nil
        }
    }
    
    public func matches(request: URLRequest, forStub stub: HTTPStubRequest) -> Bool {
        switch location {
        case .url:
            guard let string = request.url?.absoluteString else {
                return false
            }
            let matches = regex.numberOfMatches(in: string, options: [], range: NSRange(string.startIndex..., in: string)) > 0
            return matches
            
        default:
            return false
        }
    }
    
}


