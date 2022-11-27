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
//  Copyright ©2022 Immobiliare.it SpA.
//  Licensed under MIT License.
//

import Foundation

public enum RealHTTP {
    
    /// Current RealHTTP version.
    static let sdkVersion = "1.8.0"
    
    /// Identifier of the agent string.
    static let agentIdentifier = "realhttp"
    
}

// MARK: - Fetch Shortcuts

/// The following shortcuts are used to execute a request into the shared `HTTPClient.shared` instance.
extension RealHTTP {
    
    /// Fetch the request with the default client.
    public static func fetch(_ request: HTTPRequest) async throws -> HTTPResponse {
        try await HTTPClient.shared.fetch(request)
    }
    
    /// Fetch data asynchronously and return decoded object with given passed type.
    /// Object must be conform to `HTTPDecodableResponse` if you want to implement custom decode.
    ///
    /// - Returns: T?
    public static func fetch<T: HTTPDecodableResponse>(_ request: HTTPRequest, decode: T.Type) async throws -> T? {
        try await HTTPClient.shared.fetch(request).decode(decode)
    }
    
    /// Fetch data asynchronously and return the decoded object by using `Decodable` conform type.
    ///
    /// - Returns: T?
    public static func fetch<T: Decodable>(_ request: HTTPRequest, decode: T.Type, decoder: JSONDecoder = .init()) async throws -> T? {
        try await HTTPClient.shared.fetch(request).decode(decode)
    }
    
}
