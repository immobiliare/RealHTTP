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
