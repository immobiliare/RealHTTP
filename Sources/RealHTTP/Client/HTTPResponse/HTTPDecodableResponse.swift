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

// Combination of a decodable response which can be parsed via custom parser or Codable.
public typealias DecodableResponse = HTTPDecodableResponse & Decodable

// MARK: - HTTPDecodableResponse

/// If you can't implement `Decodable` you can customize your own decoding mechanism.
public protocol HTTPDecodableResponse {
    
    /// A custom decoder function.
    ///
    /// - Returns: a valid instance of `Self` or `nil`.
    static func decode(_ response: HTTPResponse) throws -> Self?
    
}

// MARK: - HTTPResponse Extension

extension HTTPResponse {
    
    /// Decode a raw response using `Decodable` object type.
    ///
    /// - Returns: `T` or `nil` if no response has been received.
    public func decode<T: Decodable>(_ decodable: T.Type, decoder: JSONDecoder = .init()) throws -> T? {
        guard let data = data else { return nil }
        
        let decodedObj = try decoder.decode(T.self, from: data)
        return decodedObj
    }
    
    /// Decode a raw response and transform it to passed `HTTPDecodableResponse` type.
    ///
    /// - Returns: T or `nil` if response is empty.
    public func decode<T: HTTPDecodableResponse>(_ decodable: T.Type) throws -> T? {
        try decodable.decode(self)
    }
    
}
