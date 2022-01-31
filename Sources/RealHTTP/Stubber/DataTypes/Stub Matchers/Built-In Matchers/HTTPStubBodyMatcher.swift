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

/// This is a simple matcher which compares the content of the body request
/// with the value assigned here.
open class HTTPStubBodyMatcher: HTTPStubMatcher {
    
    // MARK: - Private Properties
    
    /// Content to compare.
    private var content: HTTPStubDataConvertible
    
    // MARK: - Initialization
    
    /// Create a new matcher to compare this content with request's body.
    ///
    /// - Parameter content: content, can be a string or a data.
    public init(content: HTTPStubDataConvertible) {
        self.content = content
    }
    
    // MARK: - Conformance
    
    public func matches(request: URLRequest, for source: HTTPMatcherSource) -> Bool {
        guard let data = request.body else {
            return false
        }
        
        return data == content.data
    }
    
}
