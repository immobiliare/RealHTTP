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

/// A simple URL matcher.
public class HTTPURLMatcher: HTTPStubMatcherProtocol {
    
    // MARK: - Private Mat
    
    /// URL to ignore.
    private var URL: URL
    
    /// `true` to ignore query parameters.
    private var ignoreQuery: Bool
    
    // MARK: - Initialization
    
    /// Initialize to match a specified URL.
    ///
    /// - Parameters:
    ///   - URL: URL to match. If not valid initialization fails.
    ///   - ignoreQuery: `true` to params should be ignored by the matcher.
    public init?(URL: URLConvertible, ignoreQuery: Bool) {
        do {
            self.URL = try URL.asURL()
            self.ignoreQuery = ignoreQuery
        } catch {
            return nil
        }
    }
    
    // MARK: - Conformance
    
    public func matches(request: URLRequest, for source: HTTPMatcherSource) -> Bool {
        if ignoreQuery {
            return URL.baseString == request.url?.baseString
        }

        return URL.absoluteString == request.url?.absoluteString
    }
    
}
