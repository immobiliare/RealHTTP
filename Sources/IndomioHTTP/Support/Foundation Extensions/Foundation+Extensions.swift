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

// MARK: - NSNumber

extension NSNumber {
    
    internal var isBool: Bool {
        String(cString: objCType) == "c"
    }
    
}

// MARK: - String

extension String {
    
    /// Create an RFC 3986 compliant string used to compose query string in URL.
    ///
    /// - Parameter string: source string.
    /// - Returns: String
    public var queryEscaped: String {
        self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowedSet) ?? self
    }
    
}

// MARK: - Array

extension Array where Element == String {
    
    internal func joinedWithAmpersands() -> String {
        joined(separator: "&")
    }
    
}

// MARK: - CharacterSet

extension CharacterSet {
    
    /// From Alamofire.
    /// Creates a CharacterSet from RFC 3986 allowed characters.
    ///
    /// RFC 3986 states that the following characters are "reserved" characters.
    ///
    /// - General Delimiters: ":", "#", "[", "]", "@", "?", "/"
    /// - Sub-Delimiters: "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="
    ///
    /// In RFC 3986 - Section 3.4, it states that the "?" and "/" characters should not be escaped to allow
    /// query strings to include a URL. Therefore, all "reserved" characters with the exception of "?" and "/"
    /// should be percent-escaped in the query string.
    public static let urlQueryAllowedSet: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        let encodableDelimiters = CharacterSet(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")

        return CharacterSet.urlQueryAllowed.subtracting(encodableDelimiters)
    }()
    
}
