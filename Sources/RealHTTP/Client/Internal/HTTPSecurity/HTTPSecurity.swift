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

/// Security bundled options:
/// - `acceptSelfSigned`: auto-accept self signed certificates automatically (don't use in production).
/// - `credentials`: setup a credentials authentication challenge callback.
/// - `certs`: SSL pinning with given certificates instances.
/// - `bundledCerts`: SSL pinning with given certificates contained in a specified directory.
/// - `custom`: custom `HTTPSecurityProtocol` conform object.
public enum HTTPSecurity {
    case acceptSelfSigned
    case credentials(CredentialSecurity.AuthenticationCallback)
    case certs(_ certs: [SSLCertificate], usePublicKeys: Bool)
    case bundledCerts(_ dir: String = ".", usePublicKeys: Bool)
    case custom(HTTPSecurityService)
    
    /// Return the conformance classes for security option.
    ///
    /// - Returns: `HTTPSecurityProtocol`
    internal func service() -> HTTPSecurityService {
        switch self {
        case .acceptSelfSigned:
            return SelfSignedCertsSecurity()
        case .credentials(let callback):
            return CredentialSecurity(callback)
        case .certs(let certs, let usePublicKeys):
            return  CertificatesSecurity(certificates: certs, usePublicKeys: usePublicKeys)
        case .bundledCerts(let dir, let usePublicKeys):
            return CertificatesSecurity(bundledIn: dir, usePublicKeys: usePublicKeys)
        case .custom(let custom):
            return custom
        }
    }
    
}
