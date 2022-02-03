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

// MARK: - HTTPSecurity Protocol

/// This protocol allows you to customize the logic to handle custon authentication styles.
public protocol HTTPSecurity {
        
    /// Receive challange for authentication.
    ///
    /// - Parameters:
    ///   - challenge: challange.
    ///   - request: request.
    ///   - task: task associated with request.
    ///   - completionHandler: completion handler.
    func receiveChallenge(_ challenge: URLAuthenticationChallenge,
                          forRequest request: HTTPRequest, task: URLSessionTask,
                          completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)

}

// MARK: - Shortcuts for `HTTPSecurity`

public extension HTTPSecurity {
    
    /// Setup a self-signed auto accept certificates on any collection.
    /// You should never use it on production.
    ///
    /// - Returns: `HTTPSecurity`
    static func autoAcceptSelfSignedCertificates() -> HTTPSecurity {
        SelfSignedCertsSecurity()
    }
    
    /// Perform a credentials authentication challenge.
    ///
    /// - Parameter callback: callback for authentication challange.
    /// - Returns: `HTTPSecurity`
    static func credentialsSecurity(_ callback: @escaping CredentialSecurity.AuthenticationCallback) -> HTTPSecurity {
        CredentialSecurity(callback)
    }
    
    /// Perform SSL pinning.
    ///
    /// - Parameters:
    ///   - certs: SSL Certificates to use.
    ///   - usePublicKeys: true to use public keys, `false` is the default option.
    /// - Returns: `HTTPSecurity`
    static func certificates(_ certs: [SSLCertificate], usePublicKeys: Bool = false) -> HTTPSecurity {
        CertificatesSecurity(certificates: certs, usePublicKeys: usePublicKeys)
    }
    
    /// Use certs from main app bundle.
    ///
    /// - Parameters:
    ///   - dir: directory with certificates.
    ///   - usePublicKeys: true to use public keys, `false` is the default option.
    /// - Returns: HTTPSecurity
    static func certificates(bundledIn dir: String = ".", usePublicKeys: Bool = false) -> HTTPSecurity {
        CertificatesSecurity(bundledIn: dir, usePublicKeys: usePublicKeys)
    }
    
}
