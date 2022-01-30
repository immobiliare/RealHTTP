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

public protocol HTTPStubMatcher {
    
    /// Validate if source can match received request.
    ///
    /// - Parameters:
    ///   - request: request instance received.
    ///   - source: source of data.
    func matches(request: URLRequest, for source: HTTPMatcherSource) -> Bool
    
}
