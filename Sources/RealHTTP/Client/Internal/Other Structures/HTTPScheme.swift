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

/// Defines the protocol scheme for an URL.
public struct HTTPScheme: Equatable, Hashable, Codable, RawRepresentable {
    static let http: Self = "http"
    static let https: Self = "https"
    static let ftp: Self = "ftp"
    static let sftp: Self = "sftp"
    static let tel: Self = "tel"
    static let mailto: Self = "mailto"
    static let file: Self = "file"
    static let data: Self = "data"
    
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
}

extension HTTPScheme: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
    
}
