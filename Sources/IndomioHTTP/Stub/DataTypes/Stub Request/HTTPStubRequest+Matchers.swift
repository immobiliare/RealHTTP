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

extension HTTPStubRequest {
    
    /// Add specified matcher to the list of matchers for request.
    ///
    /// - Parameter matcher: matcher to add.
    /// - Returns: Self
    public func match(_ matcher: HTTPStubMatcherProtocol) -> Self {
        matchers.append(matcher)
        return self
    }
    
    /// Configure the stub request to use a regular expression matcher to intercept URLs.
    ///
    /// - Parameters:
    ///   - pattern: pattern for validation.
    ///   - options: options for regular expression.
    /// - Returns: Self
    public func match(urlRegex pattern: String, options: NSRegularExpression.Options = []) -> Self {
        guard let matcher = HTTPStubRegExMatcher(regex: pattern, options: options, in: .url) else {
            return self
        }
        
        return match(matcher)
    }
    
    /// Configure the stub request to match the request's body with a configured `Codable` object.
    ///
    /// - Parameter object: object to match.
    /// - Returns: Self
    public func match<Object: Codable & Hashable>(object: Object) -> Self {
        match(HTTPStubJSONMatcher(matchObject: object))
    }
    
    /// Match body content.
    ///
    /// - Parameter body: body content to match.
    /// - Returns: Sefl
    public func match(body: HTTPStubDataConvertible) -> Self {
        match(HTTPStubBodyMatcher(content: body))
    }
    
    /// Configure the stub request to match URI template conform to the RFC6570 <https://tools.ietf.org/html/rfc6570>.
    ///
    /// For example you can pass: `/kylef/Mockingjay` to match requests with the following URLs:
    ///     - https://github.com/kylef/WebLinking.swift
    ///     - https://github.com/kylef/{repository}
    ///     - /kylef/{repository}
    ///     - /kylef/URITemplate.swift
    ///     
    ///  as described in <https://github.com/kylef/URITemplate.swift>
    ///
    /// - Parameter uriTemplate: uri template to match, conform to RFC6570
    /// - Returns: Self
    public func match(URI uriTemplate: String) -> Self {
        match(HTTPURITemplateMatcher(URI: uriTemplate))
    }
    
    /// Configure the stub request to match a specific URL optionally ignoring query parameters.
    /// If URL is not valid no rule will be added.
    ///
    /// - Parameters:
    ///   - URL: URL target.
    ///   - options: comparison options for URL matcher.
    /// - Returns: Self
    public func match(URL: URLConvertible, options: HTTPURLMatcher.Options = .default) -> Self {
        guard let matcher = HTTPURLMatcher(URL: URL, options: options) else {
            return self
        }
        return match(matcher)
    }
    
}
