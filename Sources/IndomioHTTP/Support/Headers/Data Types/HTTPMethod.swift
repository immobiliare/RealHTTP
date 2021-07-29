//
//  IndomioNetwork
//
//  Created by the Mobile Team @ ImmobiliareLabs
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Copyright ©2021 Immobiliare.it SpA. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

/// Enum to represent a HTTP request method.
/// Generated from <https://developer.mozilla.org/de/docs/Web/HTTP/Methods>.
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
public enum HTTPMethod: String {
    case get = "GET"
    case head = "HEAD"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case connect = "CONNECT"
    case trace = "TRACE"
    case options = "OPTIONS"
    case patch = "PATCH"
}
