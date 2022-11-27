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

public extension HTTPHeaders.Element {
    
    /// Common HTTP Header fields.
    /// Generated from <https://en.wikipedia.org/wiki/List_of_HTTP_header_fields#Standard_request_fields>
    ///
    /// - `aIM`: Acceptable instance-manipulations for the request
    ///          (`A-IM: feed`)
    /// - `accept`: Media type(s) that is/are acceptable for the response. See Content negotiation
    ///             (`Accept: text/html`)
    /// - `acceptCharset`: Character sets that are acceptable (`Accept-Charset: utf-8`)
    /// - `acceptDatetime`: Acceptable version in time (`Accept-Datetime: Thu, 31 May 2007 20:35:00 GMT`)
    /// - `acceptEncoding`: List of acceptable encodings. See HTTP compression (`Accept-Encoding: gzip, deflate`)`
    /// - `acceptLanguage`: List of acceptable human languages for response. See Content negotiation (`Accept-Language: en-US`)
    /// - `accessControlRequestMethod`: Initiates a request for cross-origin resource sharing with Origin (below) (`Access-Control-Request-Method: GET`)
    /// - `accessControlRequestHeaders`: Initiates a request for cross-origin resource sharing with Origin (below) (`Access-Control-Request-Method: GET`)
    /// - `authorization`: Authentication credentials for HTTP authentication (`Authorization: Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==`)
    /// - `cacheControl`: Used to specify directives that must be obeyed by all caching mechanisms along the request-response chain (`Cache-Control: no-cache`)
    /// - `connection`: Control options for the current connection and list of hop-by-hop request fields. Must not be used with HTTP/2
    ///                 (`Connection: keep-alive Connection: Upgrade`)
    /// - `contentEncoding`: The type of encoding used on the data. See HTTP compression (`Content-Encoding: gzip`)
    /// - `contentLength`: The length of the request body in octets (8-bit bytes) (`Content-Length: 348`)
    /// - `contentDisposition`: content-Disposition response header is a header indicating if the content is expected
    ///                         to be displayed inline in the browser, that is, as a Web page or as part of a Web page,
    ///                         or as an attachment, that is downloaded and saved locally
    /// - `contentMD5`: A Base64-encoded binary MD5 sum of the content of the request body (`Content-MD5: Q2hlY2sgSW50ZWdyaXR5IQ==`)
    /// - `contentType`: The Media type of the body of the request (used with POST and PUT requests) (`Content-Type: application/x-www-form-urlencoded`)
    /// - `cookie`: An HTTP cookie previously sent by the server with Set-Cookie (below) (`Cookie: $Version=1; Skin=new;`)
    /// - `date`: The date and time at which the message was originated (in "HTTP-date" format as defined by RFC 7231 Date/Time Formats)
    ///           (`Date: Tue, 15 Nov 1994 08:12:31 GMT`)
    /// - `expect`: Indicates that particular server behaviors are required by the client (`Expect: 100-continue`)
    /// - `forwarded`: Disclose original information of a client connecting to a web server through an HTTP proxy.
    ///                (`Forwarded: for=192.0.2.60;proto=http;by=203.0.113.43 Forwarded: for=192.0.2.43, for=198.51.100.17`)
    /// - `from`: The email address of the user making the request (`From: user@example.com`)
    /// - `host`: The domain name of the server (for virtual hosting), and the TCP port number on which the server is listening.
    ///           The port number may be omitted if the port is the standard port for the service requested. Mandatory since HTTP/1.1.
    ///           If the request is generated directly in HTTP/2, it should not be used.
    ///           (`Host: en.wikipedia.org:8080 Host: en.wikipedia.org`)
    ///  - `http2Settings`: A request that upgrades from HTTP/1.1 to HTTP/2 MUST include exactly one HTTP2-Setting header field.
    ///                     The HTTP2-Settings header field is a connection-specific header field that includes parameters that
    ///                     govern the HTTP/2 connection, provided in anticipation of the server accepting the request to upgrade.
    ///                     (`HTTP2-Settings: token64`)
    ///  - `ifMatch`: Only perform the action if the client supplied entity matches the same entity on the server.
    ///               This is mainly for methods like PUT to only update a resource if it has not been modified since the user last updated it.
    ///               (`If-Match: "737060cd8c284d8af7ad3082f209582d"`)
    ///  - `ifModifiedSince`: Allows a 304 Not Modified to be returned if content is unchanged (`If-Modified-Since: Sat, 29 Oct 1994 19:43:31 GMT`)
    ///  - `ifNoneMatch`: Allows a 304 Not Modified to be returned if content is unchanged, see HTTP ETag (`If-None-Match: "737060cd8c284d8af7ad3082f209582d"`)
    ///  - `ifRange`: If the entity is unchanged, send me the part(s) that I am missing; otherwise, send me the entire new entity
    ///               (`If-Range: "737060cd8c284d8af7ad3082f209582d"`)
    ///  - `ifUnmodifiedSince`: Only send the response if the entity has not been modified since a specific time (`If-Unmodified-Since: Sat, 29 Oct 1994 19:43:31 GMT`)
    ///  - `maxForwards`: Limit the number of times the message can be forwarded through proxies or gateways (`Max-Forwards: 10`)
    ///  - `origin`: Initiates a request for cross-origin resource sharing (asks server for Access-Control-* response fields)
    ///              (`Origin: http://www.example-social-network.com`)
    ///  - `pragma`: Implementation-specific fields that may have various effects anywhere along the request-response chain (`Pragma: no-cache`)
    ///  - `proxyAuthorization`: Authorization credentials for connecting to a proxy (`Proxy-Authorization: Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==`)
    ///  - `range`: Request only part of an entity.  Bytes are numbered from 0.  See Byte serving (`Range: bytes=500-999`)
    ///  - `referer`: This is the address of the previous web page from which a link to the currently requested page was followed.
    ///               (The word "referrer" has been misspelled in the RFC as well as in most implementations to the point that it has become standard usage and is
    ///               considered correct terminology).
    ///               (`Referer: http://en.wikipedia.org/wiki/Main_Page`)
    ///  - `te`: The transfer encodings the user agent is willing to accept: the same values as for the response header field Transfer-Encoding can be used,
    ///          plus the "trailers" value (related to the "chunked" transfer method) to notify the server it expects to receive additional fields in
    ///          the trailer after the last, zero-sized, chunk.
    ///          Only trailers is supported in HTTP/2.
    ///          (`TE: trailers, deflate`)
    ///  - `trailer`: The Trailer general field value indicates that the given set of header fields is present in the trailer of a message encoded
    ///               with chunked transfer coding (`Trailer: Max-Forwards`)
    ///  - `transferEncoding`: The form of encoding used to safely transfer the entity to the user. Currently defined methods are: chunked, compress,
    ///                        deflate, gzip, identity. Must not be used with HTTP/2 (`Transfer-Encoding: chunked`)
    ///  - `userAgent`: The user agent string of the user agent (`User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:12.0) Gecko/20100101 Firefox/12.0`)
    ///  - `upgrade`: Ask the server to upgrade to another protocol. Must not be used in HTTP/2 (`Upgrade: h2c, HTTPS/1.3, IRC/6.9, RTA/x11, websocket`)
    ///  - `via`: Informs the server of proxies through which the request was sent (`Via: 1.0 fred, 1.1 example.com (Apache/1.1)`)
    ///  - `warning`: A general warning about possible problems with the entity body (`Warning: 199 Miscellaneous warning`)
    enum Name: ExpressibleByStringLiteral, Hashable, Equatable {
        case aIM
        case accept
        case acceptCharset
        case acceptDatetime
        case acceptEncoding
        case acceptLanguage
        case acceptRanges
        case accessControlRequestMethod
        case accessControlRequestHeaders
        case authorization
        case cacheControl
        case connection
        case contentEncoding
        case contentLength
        case contentDisposition
        case contentMD5
        case contentType
        case cookie
        case date
        case expect
        case forwarded
        case from
        case host
        case http2Settings
        case ifMatch
        case ifModifiedSince
        case ifNoneMatch
        case ifRange
        case ifUnmodifiedSince
        case maxForwards
        case origin
        case pragma
        case proxyAuthorization
        case range
        case referer
        // swiftlint:disable identifier_name
        case te
        case trailer
        case transferEncoding
        case userAgent
        case upgrade
        case via
        case warning
        case location
        case custom(String)
        
        /// You can create a custom header name from a literal string.
        ///
        /// - Parameter value: value.
        public init(stringLiteral value: StringLiteralType) {
            self = .custom(value)
        }
        
        // MARK: - Public Properties
        
        /// Raw value of the header name.
        public var rawValue: String {
            switch self {
            case .aIM: return "A-IM"
            case .accept: return "Accept"
            case .acceptCharset: return "Accept-Charset"
            case .acceptDatetime: return "Accept-Datetime"
            case .acceptEncoding: return "Accept-Encoding"
            case .acceptLanguage: return "Accept-Language"
            case .acceptRanges: return "Accept-Ranges"
            case .accessControlRequestMethod: return "Access-Control-Request-Method"
            case .accessControlRequestHeaders: return "Access-Control-Request-Headers"
            case .authorization: return "Authorization"
            case .cacheControl: return "Cache-Control"
            case .connection: return "Connection"
            case .contentEncoding: return "Content-Encoding"
            case .contentLength: return "Content-Length"
            case .contentDisposition: return "Content-Disposition"
            case .contentMD5: return "Content-MD5"
            case .contentType: return "Content-Type"
            case .cookie: return "Cookie"
            case .date: return "Date"
            case .expect: return "Expect"
            case .forwarded: return "Forwarded"
            case .from: return "From"
            case .host: return "Host"
            case .http2Settings: return "HTTP2-Settings"
            case .ifMatch: return "If-Match"
            case .ifModifiedSince: return "If-Modified-Since"
            case .ifNoneMatch: return "If-None-Match"
            case .ifRange: return "If-Range"
            case .ifUnmodifiedSince: return "If-Unmodified-Since"
            case .maxForwards: return "Max-Forwards"
            case .origin: return "Origin"
            case .pragma: return "Pragma"
            case .proxyAuthorization: return "Proxy-Authorization"
            case .range: return "Range"
            case .referer: return "Referer"
            case .te: return "TE"
            case .trailer: return "Trailer"
            case .transferEncoding: return "Transfer-Encoding"
            case .userAgent: return "User-Agent"
            case .upgrade: return "Upgrade"
            case .via: return "Via"
            case .warning: return "Warning"
            case .location: return "Location"
            case .custom(let v): return v
            }
        }
    }
    
}
