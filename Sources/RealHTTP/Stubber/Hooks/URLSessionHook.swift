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

/// The following hook allows you to register an `URLProtocol` which manage responses to
/// the `URLSession` architecture.
final class URLSessionHook: HTTPStubHookProtocol {
    
    func load() {
        guard let method = class_getInstanceMethod(originalClass(), originalSelector()),
              let stub = class_getInstanceMethod(URLSessionHook.self, #selector(protocolClasses)) else {
            fatalError("Could not load URLSessionHook")
        }
        method_exchangeImplementations(method, stub)
    }
    
    func unload() {
        load()
    }
    
    private func originalClass() -> AnyClass? {
        NSClassFromString("__NSCFURLSessionConfiguration") ?? NSClassFromString("NSURLSessionConfiguration")
    }
    
    private func originalSelector() -> Selector {
        #selector(getter: URLSessionConfiguration.protocolClasses)
    }
    
    @objc private func protocolClasses() -> [AnyClass] {
        [HTTPStubURLProtocol.self]
    }
    
    func isEqual(to other: HTTPStubHookProtocol) -> Bool {
        if let theOther = other as? URLSessionHook {
            return theOther == self
        }
        return false
    }
    
}
