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

/// This is a simple matcher which compares the content of the body request
/// with the value assigned here.
open class HTTPStubBodyMatcher: HTTPStubMatcherProtocol {
    
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
