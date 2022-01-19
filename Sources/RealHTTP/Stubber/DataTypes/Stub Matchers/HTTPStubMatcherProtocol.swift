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

public enum HTTPMatcherLocation {
    case body
    case headersValue
    case headersKey
    case url
}

/// Defines a generic sender for matching.
public protocol HTTPMatcherSource { }

extension HTTPStubRequest: HTTPMatcherSource {}
extension HTTPStubIgnoreRule: HTTPMatcherSource {}

// MARK: - HTTPStubMatcherProtocol

public protocol HTTPStubMatcherProtocol {
    
    /// Validate if source can match received request.
    ///
    /// - Parameters:
    ///   - request: request instance received.
    ///   - source: source of data.
    func matches(request: URLRequest, for source: HTTPMatcherSource) -> Bool
    
}
