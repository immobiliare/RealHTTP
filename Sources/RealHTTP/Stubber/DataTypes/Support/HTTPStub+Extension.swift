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

internal extension NSRegularExpression {
    
    /// Return `true` if regular expression is valid for a given string.
    ///
    /// - Parameter string: string.
    /// - Returns: Bool
    func hasMatches(_ string: String?) -> Bool {
        guard let string = string else {
            return false
        }
        
        return numberOfMatches(in: string, options: [], range: NSRange(string.startIndex..., in: string)) > 0
    }
    
}
