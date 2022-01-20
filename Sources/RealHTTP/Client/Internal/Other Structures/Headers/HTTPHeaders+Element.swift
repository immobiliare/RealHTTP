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

public extension HTTPHeaders {
    
    /// A representation of a single HTTP header's name & value pair.
    struct Element: Hashable, Equatable, CustomStringConvertible {
        
        // MARK: - Public Properties
        
        /// Name of the header.
        public let name: Name
        
        /// Value of the header.
        public let value: String
        
        // MARK: - Static Initialization
        
        /// Create the default `Accept-Encoding` header.
        public static let defaultAcceptEncoding: Element = {
            .acceptEncoding(["br", "gzip", "deflate"].encodedWithQuality())
        }()
        
        /// Create the default `Accept-Language` header generated
        /// from the current system's locale settings.
        public static let defaultAcceptLanguage: Element = {
            let value = Locale.preferredLanguages.prefix(6).encodedWithQuality()
            return .acceptLanguage(value)
        }()
        
        /// Create the default `User-Agent` header.
        /// See <https://tools.ietf.org/html/rfc7231#section-5.5.3>.
        public static let defaultUserAgent: Element = {
            let libraryVersion = "\(RealHTTP.agentIdentifier)/\(RealHTTP.sdkVersion)"
            let mainBundle = Bundle.main
            let value = "\(mainBundle.executableName)/\(mainBundle.appVersion) (\(mainBundle.bundleID); build:\(mainBundle.appBuild); \(mainBundle.osNameIdentifier)) \(libraryVersion)"
            return .userAgent(value)
        }()
        
        // MARK: - Initialization
        
        public init(name: String, value: String) {
            self.init(name: .custom(name), value: value)
        }
        
        /// Initialize a new instance of the header with given data where name of the field
        /// is taken from our list of pre-builts fields.
        ///
        /// - Parameters:
        ///   - name: name of the field.
        ///   - value: value of the field.
        public init(name: Name, value: String) {
            self.name = name
            self.value = value
        }
        
        /// Description of the header.
        public var description: String {
            "\(name.rawValue): \(value)"
        }
        
    }
    
}

    // MARK: - HTTPHeader + Authorization

public extension HTTPHeaders.Element {
    
    // MARK: - Authorization
    
    /// `Authorization` header.
    /// Consider using one of the built-in methods provided by this library in order to create valid
    /// authorization tokens styles.
    ///
    /// - Parameter rawValue: value of the header.
    /// - Returns: HTTPHeader
    static func auth(_ rawValue: String) -> HTTPHeaders.Element {
        .init(name: "Authorization", value: rawValue)
    }
    
    /// `Basic` `Authorization` header using the `username`, `password` provided.
    ///
    /// - Parameters:
    ///   - username: username of the header.
    ///   - password: password of the header.
    /// - Returns: HTTPHeader
    static func authBasic(username: String, password: String) -> HTTPHeaders.Element {
        let credential = Data("\(username):\(password)".utf8).base64EncodedString()
        return auth("Basic \(credential)")
    }
    
    /// `Bearer` `Authorization` header using the `bearerToken` provided.
    ///
    /// - Parameter bearerToken: The bearer token value.
    /// - Returns: HTTPHeader
    static func authBearerToken(_ bearerToken: String) -> HTTPHeaders.Element {
        auth("Bearer \(bearerToken)")
    }
    
    /// `OAuth` `Authorization` header using the `oAuthToken` provided.
    ///
    /// - Parameter oAuthToken: The token value.
    /// - Returns: HTTPHeader
    static func authOAuth(_ oAuthToken: String) -> HTTPHeaders.Element {
        auth("OAuth \(oAuthToken)")
    }
    
    /// Set the `x-api-key` header for authorized calls.
    ///
    /// - Parameter xAPIKey: value of the key.
    /// - Returns: HTTPHeader
    static func xAPIKey(_ xAPIKey: String) -> HTTPHeaders.Element {
        .init(name: "x-api-key", value: xAPIKey)
    }
    
}


// MARK: - HTTPHeader + Accept

public extension HTTPHeaders.Element {
    
    /// The `Accept` header.
    ///
    /// - Parameter value: `Accept` value
    /// - Returns: HTTPHeader
    static func accept(_ value: String) -> HTTPHeaders.Element {
        .init(name: .accept, value: value)
    }
    
    /// The `Accept-Charset` header.
    ///
    /// - Parameter charset: `Accept-Charset` value
    /// - Returns: HTTPHeader
    static func acceptCharset(_ charset: String) -> HTTPHeaders.Element {
        .init(name: .acceptCharset, value: charset)
    }
    
    /// The `Accept-Language` header.
    ///
    /// - Parameter language: `Accept-Language` value
    /// - Returns: HTTPHeader
    static func acceptLanguage(_ language: String) -> HTTPHeaders.Element {
        .init(name: .acceptLanguage, value: language)
    }
    
    /// The `Accept-Encoding` header.
    ///
    /// - Parameter encoding: `Accept-Encoding` value.
    /// - Returns: HTTPHeader
    static func acceptEncoding(_ encoding: String) -> HTTPHeaders.Element {
        .init(name: .acceptEncoding, value: encoding)
    }
    
}

// MARK: - HTTPHeader + Content

public extension HTTPHeaders.Element {
    
    /// `Content-Disposition` header.
    ///
    /// - Parameter value: `Content-Disposition` value.
    /// - Returns: HTTPHeader
    static func contentDisposition(_ value: String) -> HTTPHeaders.Element {
        .init(name: .contentDisposition, value: value)
    }
    
    /// `Content-Type` header.
    /// - Parameter value: `Content-Type` value.
    /// - Returns: HTTPHeader
    static func contentType(_ value: String) -> HTTPHeaders.Element {
        .init(name: .contentType, value: value)
    }
    
    /// `Content-Type` header created with presets value.
    ///
    /// - Parameter value: `HTTPContentType` presets value.
    /// - Returns: HTTPHeader.
    static func contentType(_ value: HTTPContentType) -> HTTPHeaders.Element {
        contentType(value.rawValue)
    }
    
    /// `Content-Length` header created with presets value.
    ///
    /// - Parameter value: `Content-Length` value.
    /// - Returns: HTTPHeader.
    static func contentLength(_ value: String) -> HTTPHeaders.Element {
        .init(name: .contentLength, value: value)
    }
    
    /// `User-Agent` header.
    ///
    /// - Parameter value: `User-Agent` value.
    /// - Returns: HTTPHeader
    static func userAgent(_ value: String) -> HTTPHeaders.Element {
        .init(name: .userAgent, value: value)
    }
    
}


// MARK: - HTTPHeader + Other

public extension HTTPHeaders.Element {
    
    /// `Cache-Control` header.
    ///
    /// - Parameter value: `Cache-Control` value.
    /// - Returns: HTTPHeader.
    static func cacheControl(_ value: String) -> HTTPHeaders.Element {
        .init(name: .cacheControl, value: value)
    }
    
    /// `Cache-Control` header with presets value.
    ///
    /// - Parameter value: `Cache-Control` value.
    /// - Returns: HTTPHeader.
    static func cacheControl(_ value: HTTPCacheControl) -> HTTPHeaders.Element {
        .init(name: .cacheControl, value: value.headerValue)
    }
    
}

// MARK: - Extensions

fileprivate extension Collection where Element == String {
    
    /// See https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html.
    ///
    /// - Returns: String
    func encodedWithQuality() -> String {
        enumerated().map { index, encoding in
            let quality = 1.0 - (Double(index) * 0.1)
            return "\(encoding);q=\(quality)"
        }.joined(separator: ", ")
    }
    
}
