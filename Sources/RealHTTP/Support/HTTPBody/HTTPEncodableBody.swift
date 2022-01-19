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
//  Copyright ©2021 Immobiliare.it SpA.
//  Licensed under MIT License.
//

import Foundation

public protocol HTTPEncodableBody {
    
    func encodedData() throws -> Data
            
}

extension Data: HTTPEncodableBody {
    
    public func encodedData() throws -> Data {
        self
    }
    
}

extension String: HTTPEncodableBody {
    
    public func encodedData() throws -> Data {
        self.data(using: .utf8) ?? Data()
    }
    
}
