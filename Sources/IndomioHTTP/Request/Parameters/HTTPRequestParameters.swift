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

/// Define any type of data which can be encoded in a `URLRequest` instance.
public protocol HTTPRequestParameters {
    
    /// Encode the data of the object inside the `URLRequest`.
    ///
    /// - Parameter request: request.
    func encodeParametersIn(request: inout URLRequest) throws
    
}

// MARK: - HTTPParametersDestination

/// Defines how the url encoded query string must be applied to the request.
///
/// - `auto`: for `get`, `head`, `delete` http method uses `queryString`, `httpBody` for any other http method.
/// - `queryString` sets/appends encoded query string result to existing query string.
/// - `httpBody`: sets encoded query string result as the HTTP body.
public enum HTTPParametersDestination {
    case auto
    case queryString
    case httpBody
    
    fileprivate func bestForHTTPMethod(_ method: HTTPMethod) -> HTTPParametersDestination {
        switch method {
        case .get, .head, .delete:
            return .queryString
        default:
            return .httpBody
        }
    }
    
    internal func encodesParametersInURL(_ method: HTTPMethod?) -> Bool {
        guard let method = method else {
            return true
        }
        
        switch self {
        case .auto: return [.get, .head, .delete].contains(method)
        case .queryString: return true
        case .httpBody: return false
        }
    }
    
}
