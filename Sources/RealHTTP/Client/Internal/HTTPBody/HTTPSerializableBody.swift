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

// MARK: - HTTPEncodableBody

/// This protocol represent a generic body you can attach to a request.
/// Different data encodings are different implementation of this protocol.
public protocol HTTPSerializableBody {
    
    /// Return encoded data from the body structure used.
    /// Throw an exception if something fails.
    ///
    /// - Returns: Data and additional headers to append before making the call.
    func serializeData() throws -> (data: Data, additionalHeaders: HTTPHeaders?)
            
}

// MARK: - HTTPEncodableBody (Data)

/// A simple Data instance as body of the request.
extension Data: HTTPSerializableBody {
    
    public func serializeData() throws -> (data: Data, additionalHeaders: HTTPHeaders?) {
        (self, .forData(self))
    }
    
}

// MARK: - HTTPEncodableBody (String)

/// A simple String instance as body of the request.
extension String: HTTPSerializableBody {
    
    public func serializeData() throws -> (data: Data, additionalHeaders: HTTPHeaders?) {
        let data = self.data(using: .utf8) ?? Data()
        return (data, .forData(data))
    }
    
}
