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

public struct HTTPStubCustomMatcher: HTTPStubMatcherProtocol {
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
