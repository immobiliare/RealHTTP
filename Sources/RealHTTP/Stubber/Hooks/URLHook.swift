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

/// The following hook allows to manage request from webviews.
final class URLHook: HTTPStubHookProtocol {
    
    func load() {
        URLProtocol.registerClass(HTTPStubURLProtocol.self)
    }
    
    func unload() {
        URLProtocol.unregisterClass(HTTPStubURLProtocol.self)
    }
    
    func isEqual(to other: HTTPStubHookProtocol) -> Bool {
        if let theOther = other as? URLHook {
          return theOther == self
        }
        return false
    }
    
}
