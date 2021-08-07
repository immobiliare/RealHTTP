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

public protocol HTTPSecurityProtocol {
    
    /// Validate security trust.
    ///
    /// - Parameters:
    ///   - trust: trust.
    ///   - domain: domain to validate.
    func isValid(trust: SecTrust, forDomain domain: String?) -> Bool

}
