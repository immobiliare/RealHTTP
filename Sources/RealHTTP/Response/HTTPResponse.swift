//
//  IndomioHTTP
//
//  Created by the Mobile Team @ ImmobiliareLabs
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Copyright ©2021 Immobiliare.it SpA. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

// MARK: - NoObject

public struct NoObject: HTTPDecodableResponse {
    public static func decode(_ response: HTTPRawResponse) -> Result<NoObject, HTTPError> {
        .success(NoObject())
    }
    
    private init() {}
}

// MARK: - HTTPResponseProtocol

public protocol HTTPResponseProtocol {
    
    /// The raw response from server.
    var raw: HTTPRawResponse { get }
    
    /// Decoded object if any.
    /// NOTE: Use `object` from HTTPResponse, this is to make the compiler happy.
    var anyObject: Result<Any, HTTPError> { get }
    
}

// MARK: - HTTPResponse

public struct HTTPResponse<Object: HTTPDecodableResponse>: HTTPResponseProtocol {
    
    // MARK: - Public Properties

    /// Decoded object if available.
    public let object: Result<Object, HTTPError>
    
    /// Decoded object with type erase.
    public var anyObject: Result<Any, HTTPError> {
        object as! Result<Any, HTTPError>
    }
    
    /// Raw response FROM SERVER.
    public let raw: HTTPRawResponse
    
    // MARK: - Initialization
    
    internal init(raw: HTTPRawResponse) {
        self.raw = raw
        self.object = Object.decode(raw)
        
        if case .failure(let decodeError) = self.object {
            raw.error = HTTPError(.objectDecodeFailed, error: decodeError)
        }
    }
    
}
