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

// MARK: - HTTPBody

/// Defines the body of a request, including the content's body and additional headers.
public struct HTTPBody {
    
    // MARK: - Public Static Properties
    
    /// No data to send.
    public static let empty = HTTPBody(content: Data())

    // MARK: - Public Properties
    
    /// Content of the body.
    public var content: HTTPEncodableBody
    
    // MARK: - Internal Properties
    
    /// Additional headers to set.
    internal var headers: HTTPHeaders
    
    // MARK: - Initialization
    
    public init(content: HTTPEncodableBody, headers: HTTPHeaders = .init()) {
        self.content = content
        self.headers = headers
    }
    
    // MARK: - Raw Data
    
    /// Initialize a new body with raw data.
    ///
    /// - Parameters:
    ///   - content: content data.
    ///   - mimeType: mime type to assign.
    /// - Returns: HTTPBody
    public static func data(_ content: Data, contentType mimeType: MIMEType) -> HTTPBody {
        HTTPBody(content: content, headers: .init([.contentType: mimeType.rawValue]))
    }
    
    /// Initialize a new body with raw string which will be encoded in .utf8.
    ///
    /// - Parameters:
    ///   - content: content string.
    ///   - contentType: content type to assign, by default is set to `.text.plain`
    /// - Returns: HTTPBody
    public static func string(_ content: String, contentType: MIMEType = .textPlain) -> HTTPBody {
        .data(content.data(using: .utf8) ?? Data(), contentType: contentType)
    }
    
}

// MARK: - HTTPBody for JSON

extension HTTPBody {
    
    /// Initialize a new body with an `Encodable` conform object which can be encoded using
    /// the system's `JSONEncoder` instance passed.
    ///
    /// - Returns: HTTPBody
    public static func json<T: Encodable>(_ object: T, encoder: JSONEncoder = JSONEncoder()) throws -> HTTPBody {
        let content = try encoder.encode(object)
        var body = HTTPBody.data(content, contentType: MIMEType.jsonUtf8)
        body.headers[.contentType] = MIMEType.jsonUtf8.rawValue
        return body
    }
    
    /// Initialize a new body with an object which can be converted to JSON by using
    /// the system's `JSONSerialization`'s class.
    ///
    /// - Parameters:
    ///   - object: object to serialize.
    ///   - options: options for serialization.
    /// - Returns: HTTPBody
    public static func json(_ object: Any, options: JSONSerialization.WritingOptions = []) throws -> HTTPBody {
        let content = try JSONSerialization.data(withJSONObject: object, options: options)
        var body = HTTPBody.data(content, contentType: MIMEType.jsonUtf8)
        body.headers[.contentType] = MIMEType.jsonUtf8.rawValue
        return body
    }
    
}
