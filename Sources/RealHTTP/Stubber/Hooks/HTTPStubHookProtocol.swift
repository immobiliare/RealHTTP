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

/// The following protocol defines a subclass of `URLProtocol` which manage
/// the response for `URLSession`.
public protocol HTTPStubHookProtocol {
    
    /// Load an hook.
    func load()
    
    /// Unload an hook.
    func unload()
    
    /// Compare to another hook instance.
    /// - Parameter other: other hook instance.
    func isEqual(to other: HTTPStubHookProtocol) -> Bool

}

extension HTTPStubHookProtocol where Self: Equatable {
    
    func isEqual(to other: HTTPStubHookProtocol) -> Bool {
        if let theOther = other as? Self {
            return theOther == self
        }
        return false
    }
    
}

func ==(lhs: HTTPStubHookProtocol, rhs: HTTPStubHookProtocol) -> Bool {
    lhs.isEqual(to: rhs)
}
