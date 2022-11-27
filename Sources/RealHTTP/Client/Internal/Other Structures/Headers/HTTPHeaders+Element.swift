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

public extension HTTPHeaders {
    
    /// A representation of a single HTTP header's name & value pair.
    struct Element: Hashable, Equatable, Comparable, CustomStringConvertible {
        
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
            // swiftlint:disable line_length
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
        
        public static func ==(lhs: Element, rhs: Element) -> Bool {
            lhs.name.rawValue == rhs.name.rawValue && lhs.value == rhs.value
        }
        
        public static func < (lhs: Element, rhs: Element) -> Bool {
            lhs.name.rawValue.lowercased().compare(rhs.name.rawValue.lowercased()) == .orderedAscending
        }
        
    }
    
}

    // MARK: - HTTPHeader + Authorization

public extension HTTPHeaders.Element {
    
    // MARK: - Authorization
    
    /// The HTTP Authorization request header can be used to provide credentials
    /// that authenticate a user agent with a server, allowing access to a protected resource.
    /// Example: `Authorization: <auth-scheme> <authorisation-parameters>`
    ///
    /// NOTE:
    /// Consider using one of the built-in methods provided by this library
    /// in order to create valid authorization tokens styles.
    ///
    /// - Parameter rawValue: value of the header.
    /// - Returns: `HTTPHeaders.Element`
    static func auth(_ rawValue: String) -> HTTPHeaders.Element {
        .init(name: "Authorization", value: rawValue)
    }
    
    /// `Basic` `Authorization` header using the `username`, `password` provided.
    /// It is a simple authentication scheme built into the HTTP protocol.
    /// The client sends HTTP requests with the Authorization header that
    /// contains the word Basic, followed by a space and a base64-encoded
    /// in form of `string username: password` (non-encrypted).
    ///
    /// Example: `Authorization: Basic AXVubzpwQDU1dzByYM==`
    ///
    /// - Parameters:
    ///   - username: username of the header.
    ///   - password: password of the header.
    /// - Returns: `HTTPHeaders.Element`
    static func authBasic(username: String, password: String) -> HTTPHeaders.Element {
        let credential = Data("\(username):\(password)".utf8).base64EncodedString()
        return auth("Basic \(credential)")
    }
    
    /// Commonly known as token authentication. It is an HTTP authentication
    /// scheme that involves security tokens called bearer tokens.
    /// As the name depicts “Bearer Authentication” gives access to the bearer of this token.
    ///
    /// The bearer token is a cryptic string, usually generated by the server in
    /// response to a login request. The client must send this token in the
    /// Authorization header while requesting to protected resources.
    /// It's commonly used for JWT authentication.
    ///
    /// Example: `Authorization: Bearer <token>`
    ///
    /// - Parameter bearerToken: Arbitrary string that specifies how the bearer token is formatted.
    /// - Returns: `HTTPHeaders.Element`
    static func authBearerToken(_ bearerToken: String) -> HTTPHeaders.Element {
        auth("Bearer \(bearerToken)")
    }
    
    /// OAuth 1.0 permits client applications to access data provided by a third-party API.
    /// With OAuth 2.0, you first retrieve an access token for the API, then use that token
    /// to authenticate future requests. Getting to information via OAuth 2.0
    /// flow varies greatly between API service providers, but typically involves
    /// a few requests back and forward between client application, user, and API.
    ///
    /// Example: `Authorization: Bearer hY_9.B5f-4.1BfE`
    ///
    /// - Parameter oAuthToken: The token value.
    /// - Returns: `HTTPHeaders.Element`
    static func authOAuth(_ oAuthToken: String) -> HTTPHeaders.Element {
        auth("OAuth \(oAuthToken)")
    }
    
    /// An API key is a token that a client provides when making API calls.
    /// Example: `X-API-Key: abcdefgh123456789`
    ///
    /// - Parameter xAPIKey: value of the key.
    /// - Returns: `HTTPHeaders.Element`
    static func xAPIKey(_ xAPIKey: String) -> HTTPHeaders.Element {
        .init(name: "X-API-Key", value: xAPIKey)
    }
    
}

// MARK: - HTTPHeader + Accept

/// Documentation for available HTTP Headers can be found here:
/// <https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html>
public extension HTTPHeaders.Element {
    
    /// The `Accept` request-header field can be used to specify certain media types which
    /// are acceptable for the response.
    /// Example: `audio/*; q=0.2, audio/basic`.
    ///
    /// - Parameter value: `Accept` value
    /// - Returns: `HTTPHeader.Element`
    static func accept(_ value: String) -> HTTPHeaders.Element {
        .init(name: .accept, value: value)
    }
    
    /// The `Accept-Charset` request-header field can be used to indicate what character
    /// sets are acceptable for the response.
    /// Example: `iso-8859-5, unicode-1-1;q=0.8`
    ///
    /// - Parameter charset: `Accept-Charset` value
    /// - Returns: `HTTPHeader.Element`
    static func acceptCharset(_ charset: String) -> HTTPHeaders.Element {
        .init(name: .acceptCharset, value: charset)
    }
    
    /// The `Accept-Language` request-header field is similar to Accept,
    /// but restricts the set of natural languages that are preferred
    /// as a response to the request.
    /// A list of options is available here:
    /// <https://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.10>
    ///
    /// Example: `Accept-Language: da, en-gb;q=0.8, en;q=0.7`
    ///
    /// - Parameter language: `Accept-Language` value
    /// - Returns: `HTTPHeader.Element`
    static func acceptLanguage(_ language: String) -> HTTPHeaders.Element {
        .init(name: .acceptLanguage, value: language)
    }
    
    /// The Accept-Ranges response-header field allows the server to
    /// indicate its acceptance of range requests for a resource.
    /// Range units are defined here:
    /// <https://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.12>
    ///
    /// Example: `Accept-Ranges: bytes`
    ///
    /// - Parameter ranges: ranges accepted.
    /// - Returns: `HTTPHeader.Element`
    static func acceptRanges(_ ranges: String) -> HTTPHeaders.Element {
        .init(name: .acceptRanges, value: ranges)
    }
    
    /// The Accept-Encoding request-header field is similar to Accept, but restricts
    /// the content-codings (<https://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.5>)
    /// that are acceptable in the response.
    ///
    /// Example: `compress, gzip`
    ///
    /// - Parameter encoding: `Accept-Encoding` value.
    /// - Returns: `HTTPHeader.Element`
    static func acceptEncoding(_ encoding: String) -> HTTPHeaders.Element {
        .init(name: .acceptEncoding, value: encoding)
    }
    
}

// MARK: - HTTPHeader + Content

public extension HTTPHeaders.Element {
    
    /// `Content-Disposition` header.
    /// The `Content-Disposition` header indicate if the content is expected to be displayed inline
    /// in the browser, that is, as a Web page or as part of a Web page, or as an attachment,
    /// that is downloaded and saved locally.
    /// More info <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition>
    ///
    /// Example: `Content-Disposition: inline`
    ///
    /// - Parameter value: `Content-Disposition` value.
    /// - Returns: HTTPHeader
    static func contentDisposition(_ value: String) -> HTTPHeaders.Element {
        .init(name: .contentDisposition, value: value)
    }
    
    /// The `Content-Type` entity-header field indicates the media type of the entity-body
    /// sent to the recipient or, in the case of the HEAD method,
    /// the media type that would have been sent had the request been a GET.
    /// The following method it's not type-safe.
    ///
    /// Example: `text/html; charset=ISO-8859-4`
    ///
    /// - Parameter value: `Content-Type` value.
    /// - Returns: HTTPHeader
    static func contentType(_ value: String) -> HTTPHeaders.Element {
        .init(name: .contentType, value: value)
    }
    
    /// The `Content-Type` entity-header field indicates the media type of the entity-body
    /// sent to the recipient or, in the case of the HEAD method,
    /// the media type that would have been sent had the request been a GET.
    /// The following method it's type-safe.
    ///
    /// Example: `text/html; charset=ISO-8859-4`
    ///
    /// - Parameter value: `HTTPContentType` presets value.
    /// - Returns: HTTPHeader.
    static func contentType(_ value: HTTPContentType) -> HTTPHeaders.Element {
        contentType(value.rawValue)
    }
    
    /// The `Content-Length` entity-header field indicates the size of the entity-body,
    /// in decimal number of OCTETs, sent to the recipient or,
    /// in the case of the HEAD method, the size of the entity-body
    /// that would have been sent had the request been a GET.
    ///
    /// Example: `3495`
    ///
    /// - Parameter value: `Content-Length` value.
    /// - Returns: HTTPHeader.
    static func contentLength(_ value: String) -> HTTPHeaders.Element {
        .init(name: .contentLength, value: value)
    }
    
}

// MARK: - HTTPHeader + Other

public extension HTTPHeaders.Element {
    
    /// The `User-Agent` request-header field contains information about the
    /// user agent originating the request.
    ///
    /// Example: `CERN-LineMode/2.15 libwww/2.17b3`
    ///
    /// - Parameter value: `User-Agent` value.
    /// - Returns: HTTPHeader
    static func userAgent(_ value: String) -> HTTPHeaders.Element {
        .init(name: .userAgent, value: value)
    }
    
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

internal extension Collection where Element == String {
    
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
