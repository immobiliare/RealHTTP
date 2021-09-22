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

public protocol HTTPResponseProtocol {
    
    var rawResponse: HTTPRawResponse { get }
    
    var anyObject: Result<Any, HTTPError> { get }
}

// MARK: - HTTPResponse

public struct HTTPResponse<Object: HTTPDecodableResponse>: HTTPResponseProtocol {
    
    // MARK: - Public Properties

    /// Decoded object if available.
    public let object: Result<Object, HTTPError>
    
    
    public var anyObject: Result<Any, HTTPError> {
        object as! Result<Any, HTTPError>
    }
    
    /// Raw response.
    public let rawResponse: HTTPRawResponse
    
    // MARK: - Initialization
    
    internal init(rawResponse: HTTPRawResponse) {
        self.rawResponse = rawResponse
        self.object = Object.decode(rawResponse)
        
        if case .failure(let decodeError) = self.object {
            rawResponse.error = HTTPError(.objectDecodeFailed, error: decodeError)
        }
    }
    
}
