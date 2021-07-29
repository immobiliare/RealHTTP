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

// MARK: - HTTPRequestBuilderProtocol

/// This protocol is used to configure how the `URLRequest` is made when an `HTTPRequest` instance
/// must be executed in a `HTTPClient`.
/// Generally you should never need to intercept and modify this behaviour, but in case this is the
/// right way to accomplish it.
public protocol HTTPRequestBuilderProtocol {
    
    /// How the parameters must be encoded into the request.
    var paramsEncoding: HTTPParametersEncoding { get set }
    
    /// Create an `URLRequest` instance for a request when it runs on a `HTTPClient`.
    ///
    /// - Parameters:
    ///   - request: request to execute.
    ///   - client: destination client
    func urlRequest(for request: HTTPRequestProtocol, in client: HTTPClient) throws -> URLRequest
    
}

// MARK: - HTTPParametersEncoding

/// Defines how the url encoded query string must be applied to the request.
///
/// - `auto`: for `get`, `head`, `delete` http method uses `queryString`, `httpBody` for any other http method.
/// - `queryString` sets/appends encoded query string result to existing query string.
/// - `httpBody`: sets encoded query string result as the HTTP body.
public enum HTTPParametersEncoding {
    case auto
    case queryString
    case httpBody
    
    fileprivate func bestForHTTPMethod(_ method: HTTPMethod) -> HTTPParametersEncoding {
        switch method {
        case .get, .head, .delete:
            return .queryString
        default:
            return .httpBody
        }
    }
    
    internal func encodesParametersInURL(_ method: HTTPMethod) -> Bool {
        switch self {
        case .auto: return [.get, .head, .delete].contains(method)
        case .queryString: return true
        case .httpBody: return false
        }
    }
    
}
