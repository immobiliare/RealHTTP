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

public struct HTTPStubCustomMatcher: HTTPStubMatcher {
    public typealias Handler = (URLRequest, HTTPMatcherSource) -> Bool
    
    // MARK: - Private Properties
    
    private var callback: Handler
    
    // MARK: - Initialize
    
    /// Initialize a new stub custom matcher with given function.
    ///
    /// - Parameter callback: callback to call.
    public init(_ callback: @escaping Handler) {
        self.callback = callback
    }
    
    // MARK: - Protocol
    
    public func matches(request: URLRequest, for source: HTTPMatcherSource) -> Bool {
        callback(request, source)
    }
    
}
