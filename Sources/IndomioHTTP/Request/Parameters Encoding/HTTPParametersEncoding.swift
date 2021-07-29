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

/// A type used to define how a set of parameters are applied to a `URLRequest`.
public protocol HTTPParametersEncoding {
    
    /// Creates a `URLRequest` by encoding parameters and applying them on the passed request.
    ///
    /// - Parameters:
    ///   - urlRequest: request.
    ///   - parameters: parameters.
    func encode(_ urlRequest: URLRequest, with parameters: HTTPParameters?) throws -> URLRequest
}
