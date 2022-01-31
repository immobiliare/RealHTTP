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

/// A simple URL matcher.
public class HTTPStubURLMatcher: HTTPStubMatcher {
    
    // MARK: - Private Mat
    
    /// URL to ignore.
    private var URL: URL
    
    /// Comparison options.
    private var options: Options
    
    // MARK: - Initialization
    
    /// Initialize to match a specified URL.
    ///
    /// - Parameters:
    ///   - URL: URL to match. If not valid initialization fails.
    ///   - ignoreQuery: `true` to params should be ignored by the matcher.
    public init?(URL url: URL, options: Options) {
        self.URL = url
        self.options = options
    }
    
    // MARK: - Conformance
    
    public func matches(request: URLRequest, for source: HTTPMatcherSource) -> Bool {
        guard var targetURL = request.url else {
            return false
        }
        
        if options.contains(.ignoreQueryParameters) {
            if let base = targetURL.baseString {
                targetURL = Foundation.URL(string: base)!
            }
        }
        
        if options.contains(.ignorePath) {
            if let host = targetURL.host, let scheme = targetURL.scheme {
                targetURL = Foundation.URL(string: "\(scheme)://\(host)")!
            }
        }
        
        return URL.absoluteString == targetURL.absoluteString
    }
    
}

// MARK: HTTPURLMatcher.Options

extension HTTPStubURLMatcher {
    
    /// Defines the options for url matching.
    public struct Options: OptionSet {
        public let rawValue: Int
        
        /// Ignore query parameters from comparison.
        public static let ignoreQueryParameters = Options(rawValue: 1 << 0)
        
        /// Ignore path (route) components from comparison.
        public static let ignorePath = Options(rawValue: 1 << 1)

        /// Include all the options.
        public static let `default`: Options = [.ignoreQueryParameters]
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    
}
