//
//  IndomioHTTP
//
//  Created by the Mobile Team @ ImmobiliareLabs
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Copyright ©2022 Immobiliare.it SpA. All rights reserved.
//  Licensed under MIT License.
//
//  ============================================
//  The following implementation was created by:
//  Kyle Fuller <https://github.com/kylef>
//  for URITemplate
//  <https://github.com/kylef/URITemplate.swift>

import Foundation

public class HTTPStubIgnoreRule: Equatable {
    
    // MARK: - Public Properties
    
    /// Unique identifier of the rule.
    private var uuid = UUID().uuidString
    
    /// Matcher which validate the ignore rule. When all matchers are valid
    /// the request will be ignored.
    public private(set) var matchers: [HTTPStubMatcher]
    
    // MARK: - Initialization
    
    /// Initialize with matchers list.
    ///
    /// - Parameter matchers: matchers.
    public init(_ matchers: HTTPStubMatcher...) {
        self.matchers = matchers
    }
    
    // MARK: - Public Functions
    
    /// Add specified matcher to the list of matchers for request.
    ///
    /// - Parameter matcher: matcher to add.
    /// - Returns: Self
    public func match(_ matcher: HTTPStubMatcher) -> Self {
        matchers.append(matcher)
        return self
    }
    
    /// Configure the ignore rule to match a specific URL optionally ignoring query parameters.
    /// If URL is not valid no rule will be added.
    ///
    /// - Parameters:
    ///   - URL: URL target.
    ///   - options: comparison options for URL matcher.
    /// - Returns: Self
    public func match(url: URL, options: HTTPStubURLMatcher.Options = .default) -> Self {
        guard let matcher = HTTPStubURLMatcher(URL: url, options: options) else {
            return self
        }
        return match(matcher)
    }
    
    /// Configure the ignore rule to use a regular expression matcher to intercept URLs.
    ///
    /// - Parameters:
    ///   - pattern: pattern for validation.
    ///   - options: options for regular expression.
    /// - Returns: Self
    public func match(urlRegex pattern: String, options: NSRegularExpression.Options = []) throws -> Self {
        let matcher = try HTTPStubRegExMatcher(regex: pattern, options: options, in: .url)
        return match(matcher)
    }
    
    public static func == (lhs: HTTPStubIgnoreRule, rhs: HTTPStubIgnoreRule) -> Bool {
        lhs.uuid == rhs.uuid
    }
    
    // MARK: - Internal Functions
    
    internal func matches(_ urlRequest: URLRequest) -> Bool {
        for matcher in matchers {
            if matcher.matches(request: urlRequest, for: self) == false {
                return false
            }
        }
        
        return true
    }
    
}
