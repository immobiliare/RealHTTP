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

/// Extension to support JSON body.
extension HTTPBody {
    
    /// Initialize a new body with an object conform to `Encodable` which will converted to a JSON string.
    ///
    /// - Returns: HTTPBody
    public static func json<T: Encodable>(_ object: T, encoder: JSONEncoder = .init()) -> HTTPBody {
        let content = JSONEncodable(object, encoder: encoder)
        let body = HTTPBody(content: content, headers: .init([
            .contentType: MIMEType.json.rawValue
        ]))
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
        let content = JSONSerializable(object, options: options)
        let body = HTTPBody(content: content, headers: .init([
            .contentType: MIMEType.json.rawValue
        ]))
        return body
    }
    
}
