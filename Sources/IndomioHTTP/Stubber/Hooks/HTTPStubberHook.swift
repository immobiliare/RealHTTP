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


/// The following protocol defines a subclass of `URLProtocol` which manage
/// the response for `URLSession`.
public protocol HTTPStubberHook {
    
    /// Load an hook.
    func load()
    
    /// Unload an hook.
    func unload()
    
    /// Compare to another hook instance.
    /// - Parameter other: other hook instance.
    func isEqual(to other: HTTPStubberHook) -> Bool

}

extension HTTPStubberHook where Self: Equatable {
    
    func isEqual(to other: HTTPStubberHook) -> Bool {
        if let theOther = other as? Self {
            return theOther == self
        }
        return false
    }
    
}

func ==(lhs: HTTPStubberHook, rhs: HTTPStubberHook) -> Bool {
    lhs.isEqual(to: rhs)
}
