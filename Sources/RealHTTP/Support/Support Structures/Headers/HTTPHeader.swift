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
//  Copyright ©2021 Immobiliare.it SpA.
//  Licensed under MIT License.
//

import Foundation

/// A representation of a single HTTP header's name & value pair.
public struct HTTPHeader: Hashable, Equatable, CustomStringConvertible, Sendable {
    
    /// Name of the header.
    public let name: String
    
    /// Value of the header.
    public let value: String
    
    /// Initialize a new instance of the header with given data.
    ///
    /// - Parameters:
    ///   - name: name of the header.
    ///   - value: value of the header.
    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
    
    /// Initialize a new instance of the header with given data where name of the field
    /// is taken from our list of pre-builts fields.
    ///
    /// - Parameters:
    ///   - name: name of the field.
    ///   - value: value of the field.
    public init(name: HTTPHeaderField, value: String) {
        self.init(name: name.rawValue, value: value)
    }
    
    /// Description of the header.
    public var description: String {
        "\(name): \(value)"
    }
    
}

// MARK: - HTTPHeader + Authorization

public extension HTTPHeader {
    
    // MARK: - Authorization
    
    /// `Authorization` header.
    /// Consider using one of the built-in methods provided by this library in order to create valid
    /// authorization tokens styles.
    ///
    /// - Parameter rawValue: value of the header.
    /// - Returns: HTTPHeader
    static func auth(_ rawValue: String) -> HTTPHeader {
        HTTPHeader(name: "Authorization", value: rawValue)
    }
    
    /// `Basic` `Authorization` header using the `username`, `password` provided.
    ///
    /// - Parameters:
    ///   - username: username of the header.
    ///   - password: password of the header.
    /// - Returns: HTTPHeader
    static func authBasic(username: String, password: String) -> HTTPHeader {
        let credential = Data("\(username):\(password)".utf8).base64EncodedString()
        return auth("Basic \(credential)")
    }
    
    /// `Bearer` `Authorization` header using the `bearerToken` provided.
    ///
    /// - Parameter bearerToken: The bearer token value.
    /// - Returns: HTTPHeader
    static func authBearerToken(_ bearerToken: String) -> HTTPHeader {
        auth("Bearer \(bearerToken)")
    }
    
    /// `OAuth` `Authorization` header using the `oAuthToken` provided.
    ///
    /// - Parameter oAuthToken: The token value.
    /// - Returns: HTTPHeader
    static func authOAuth(_ oAuthToken: String) -> HTTPHeader {
        auth("OAuth \(oAuthToken)")
    }
    
    /// Set the `x-api-key` header for authorized calls.
    ///
    /// - Parameter xAPIKey: value of the key.
    /// - Returns: HTTPHeader
    static func xAPIKey(_ xAPIKey: String) -> HTTPHeader {
        HTTPHeader(name: "x-api-key", value: xAPIKey)
    }
    
}

// MARK: - HTTPHeader + Accept

public extension HTTPHeader {
        
    /// The `Accept` header.
    ///
    /// - Parameter value: `Accept` value
    /// - Returns: HTTPHeader
    static func accept(_ value: String) -> HTTPHeader {
        HTTPHeader(name: .accept, value: value)
    }
    
    /// The `Accept-Charset` header.
    ///
    /// - Parameter charset: `Accept-Charset` value
    /// - Returns: HTTPHeader
    static func acceptCharset(_ charset: String) -> HTTPHeader {
        HTTPHeader(name: .acceptCharset, value: charset)
    }
    
    /// The `Accept-Language` header.
    ///
    /// - Parameter language: `Accept-Language` value
    /// - Returns: HTTPHeader
    static func acceptLanguage(_ language: String) -> HTTPHeader {
        HTTPHeader(name: .acceptLanguage, value: language)
    }
    
    /// The `Accept-Encoding` header.
    ///
    /// - Parameter encoding: `Accept-Encoding` value.
    /// - Returns: HTTPHeader
    static func acceptEncoding(_ encoding: String) -> HTTPHeader {
        HTTPHeader(name: .acceptEncoding, value: encoding)
    }
    
}

// MARK: - HTTPHeader + Content

public extension HTTPHeader {
    
    /// `Content-Disposition` header.
    ///
    /// - Parameter value: `Content-Disposition` value.
    /// - Returns: HTTPHeader
    static func contentDisposition(_ value: String) -> HTTPHeader {
        HTTPHeader(name: .contentDisposition, value: value)
    }

    /// `Content-Type` header.
    /// - Parameter value: `Content-Type` value.
    /// - Returns: HTTPHeader
    static func contentType(_ value: String) -> HTTPHeader {
        HTTPHeader(name: .contentType, value: value)
    }
    
    /// `Content-Type` header created with presets value.
    ///
    /// - Parameter value: `HTTPContentType` presets value.
    /// - Returns: HTTPHeader.
    static func contentType(_ value: HTTPContentType) -> HTTPHeader {
        contentType(value.rawValue)
    }
    
    /// `Content-Length` header created with presets value.
    ///
    /// - Parameter value: `Content-Length` value.
    /// - Returns: HTTPHeader.
    static func contentLength(_ value: String) -> HTTPHeader {
        HTTPHeader(name: .contentLength, value: value)
    }

    /// `User-Agent` header.
    ///
    /// - Parameter value: `User-Agent` value.
    /// - Returns: HTTPHeader
    static func userAgent(_ value: String) -> HTTPHeader {
        HTTPHeader(name: .userAgent, value: value)
    }
    
}

// MARK: - HTTPHeader + Other

public extension HTTPHeader {
    
    /// `Cache-Control` header.
    ///
    /// - Parameter value: `Cache-Control` value.
    /// - Returns: HTTPHeader.
    static func cacheControl(_ value: String) -> HTTPHeader {
        HTTPHeader(name: .cacheControl, value: value)
    }
    
    /// `Cache-Control` header with presets value.
    ///
    /// - Parameter value: `Cache-Control` value.
    /// - Returns: HTTPHeader.
    static func cacheControl(_ value: HTTPCacheControl) -> HTTPHeader {
        HTTPHeader(name: .cacheControl, value: value.headerValue)
    }
    
}
