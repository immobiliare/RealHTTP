//
//  File.swift
//  
//
//  Created by Daniele Margutti on 26/12/21.
//

import Foundation

public struct URIScheme: Equatable, Hashable, Codable, RawRepresentable {
    
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
}

extension URIScheme: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

public extension URIScheme {
    static let http: Self = "http"
    static let https: Self = "https"
    static let ftp: Self = "ftp"
    static let sftp: Self = "sftp"
    static let tel: Self = "tel"
    static let mailto: Self = "mailto"
    static let file: Self = "file"
    static let data: Self = "data"
}
