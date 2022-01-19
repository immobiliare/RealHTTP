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

extension HTTPBody {
    
    /// Initialize a new body with an `Encodable` conform object which can be encoded using
    /// the system's `JSONEncoder` instance passed.
    ///
    /// - Returns: HTTPBody
    public static func json<T: Encodable>(_ object: T, encoder: JSONEncoder = JSONEncoder()) throws -> HTTPBody {
        let content = try encoder.encode(object)
        var body = HTTPBody.data(content, contentType: .application.json.appending(.characterSet, value: .utf8))
        body.headers[.contentType] = MIMEType.application.json.rawValue
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
        var body = HTTPBody.data(content, contentType: .application.json.appending(.characterSet, value: .utf8))
        body.headers[.contentType] = MIMEType.application.json.rawValue
        return body
    }
    
}
