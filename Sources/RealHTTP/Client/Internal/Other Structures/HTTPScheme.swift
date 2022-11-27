//
//  RealHTTP
//  Lightweight Async/Await Network Layer/Stubber for Swift
//
//  Created & Maintained by Mobile Platforms Team @ ImmobiliareLabs.it
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Created by: Daniele Margutti <hello@danielemargutti.com>

//  CONTRIBUTORS:
//  Thank you to all the contributors who made this project better:
//  <https://github.com/immobiliare/RealHTTP/graphs/contributors>
//
//  Copyright ©2022 Immobiliare.it SpA.
//  Licensed under MIT License.
//

import Foundation

/// Defines the protocol scheme for an URL.
public struct HTTPScheme: Equatable, Hashable, Codable, RawRepresentable, CustomStringConvertible {
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
    
    public var description: String {
        rawValue
    }
    
}

extension HTTPScheme: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
    
}
