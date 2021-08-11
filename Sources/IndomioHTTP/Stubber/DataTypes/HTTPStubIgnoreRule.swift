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
    public let matchers: [HTTPStubMatcherProtocol]
    
    // MARK: - Initialization
    
    public init(matchers: [HTTPStubMatcherProtocol] = []) {
        self.matchers = matchers
    }
    
    // MARK: - Public Functions
    
    public func match(url: String, ignoreQuery: Bool) -> Self {
        return self
    }
    
    public func match(urlRegex pattern: String, options: NSRegularExpression.Options = []) -> Self {
        return self
    }
    
    public static func == (lhs: HTTPStubIgnoreRule, rhs: HTTPStubIgnoreRule) -> Bool {
        lhs.uuid == rhs.uuid
    }
    
}
