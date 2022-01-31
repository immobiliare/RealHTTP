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

/// Defines a generic data which can be assigned as response to a stubbed request.
/// Both Data and String types are conform to this protocol.
public protocol HTTPStubDataConvertible {
    var data: Data? { get }
}

extension String: HTTPStubDataConvertible {
    public var data: Data? { self.data(using: .utf8) }
}

extension Data: HTTPStubDataConvertible {
    public var data: Data? { self }
}
