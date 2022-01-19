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
