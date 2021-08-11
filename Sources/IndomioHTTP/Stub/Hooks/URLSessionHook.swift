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

/// The following hook allows you to register an `URLProtocol` which manage responses to
/// the `URLSession` architecture.
final class URLSessionHook: HTTPStubberHook {
    
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
    
    func isEqual(to other: HTTPStubberHook) -> Bool {
        if let theOther = other as? URLSessionHook {
            return theOther == self
        }
        return false
    }
    

}
