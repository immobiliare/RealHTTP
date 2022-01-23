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

/// Enum to represent a HTTP request method.
/// <https://tools.ietf.org/html/rfc7231#section-4.3>
/// In case you need of a custom HTTP Method you can create an extension:
///
/// ```swift
/// extension HTTPMethod {
///   static let custom = HTTPMethod(rawValue: "CUSTOM_METHOD")
/// }
/// ```
///
/// - `get`: The GET method requests a representation of the specified resource. Requests using GET should only retrieve data.
/// - `head`: The HEAD method asks for a response identical to that of a GET request, but without the response body.
/// - `post`: The POST method is used to submit an entity to the specified resource, often causing a change in state or side effects on the server.
/// - `put`: The PUT method replaces all current representations of the target resource with the request payload.
/// - `delete`: The DELETE method deletes the specified resource.
/// - `connect`: The CONNECT method establishes a tunnel to the server identified by the target resource.
/// - `trace`: The TRACE method performs a message loop-back test along the path to the target resource.
/// - `options`: The OPTIONS method is used to describe the communication options for the target resource.
/// - `patch`: The PATCH method is used to apply partial modifications to a resource.
public struct HTTPMethod: RawRepresentable, Equatable, Hashable, CaseIterable  {
    
    public static var allCases: [HTTPMethod] = [.connect, .delete, .get, .head, .options, .patch, .post, .put, .trace]
    
    // MARK: - Static Values
    
    public static let connect = HTTPMethod(rawValue: "CONNECT")
    public static let delete = HTTPMethod(rawValue: "DELETE")
    public static let get = HTTPMethod(rawValue: "GET")
    public static let head = HTTPMethod(rawValue: "HEAD")
    public static let options = HTTPMethod(rawValue: "OPTIONS")
    public static let patch = HTTPMethod(rawValue: "PATCH")
    public static let post = HTTPMethod(rawValue: "POST")
    public static let put = HTTPMethod(rawValue: "PUT")
    public static let trace = HTTPMethod(rawValue: "TRACE")
    
    // MARK: - Public Properties
    
    public let rawValue: String
    
    // MARK: - Initialization
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
}
