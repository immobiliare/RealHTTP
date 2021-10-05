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
