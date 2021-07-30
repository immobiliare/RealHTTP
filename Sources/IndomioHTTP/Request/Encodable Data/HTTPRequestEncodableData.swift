//
//  IndomioNetwork
//
//  Created by the Mobile Team @ ImmobiliareLabs
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Copyright ©2021 Immobiliare.it SpA. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

/// Define any type of data which can be encoded in a `URLRequest` instance.
public protocol HTTPRequestEncodableData {
    
    /// Encode the data of the object inside the `URLRequest`.
    ///
    /// - Parameter request: request.
    func encodeParametersIn(request: inout URLRequest) throws
    
}
