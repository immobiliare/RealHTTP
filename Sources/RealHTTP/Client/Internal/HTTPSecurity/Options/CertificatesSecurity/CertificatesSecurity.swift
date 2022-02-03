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

/// `CertificatesSecurity` is used to make SSL pinning.
open class CertificatesSecurity: HTTPSecurity {
    
    // MARK: - Public Properties

    /// Should the domain name be validated?
    open var validatedDomainName = true
    
    /// The certificates.
    var certificates: [Data]?
    
    /// The public keys
    var publicKeys: [SecKey]?
    
    /// Use public keys or certificate validation?
    var usePublicKeys = false
    
    // MARK: - Initialization
    
    /// Initialize a new HTTPSecurity instance with given certificates.
    ///
    /// - Parameters:
    ///   - certificates: SSL Certificates to use.
    ///   - usePublicKeys: true to use public keys, `false` is the default option.
    public init(certificates: [SSLCertificate], usePublicKeys: Bool = false) {
        self.usePublicKeys = usePublicKeys
        
        if self.usePublicKeys {
            self.publicKeys = certificates.compactMap { cert in
                if let data = cert.certData , cert.publicKey == nil  {
                    cert.publicKey = data.extractPublicKey()
                }
                guard let publicKey = cert.publicKey else {
                    return nil
                }
                return publicKey
            }
        } else {
            self.certificates = certificates.compactMap {
                $0.certData
            }
        }
    }
    
    /// Use certs from main app bundle.
    ///
    /// - Parameter usePublicKeys: is to specific if the publicKeys or certificates should be used for SSL pinning validation
    public convenience init(bundledIn directory: String = ".", usePublicKeys: Bool = false) {
        let fileURLs = Bundle.main.paths(forResourcesOfType: "cer", inDirectory: directory).map({
            URL(fileURLWithPath: $0 as String)
        })
        
        let certificates = SSLCertificate.fromFileURLs(fileURLs)
        self.init(certificates: certificates, usePublicKeys: usePublicKeys)
    }
    
    // MARK: - Conformance
    
    open func receiveChallenge(_ challenge: URLAuthenticationChallenge, forRequest request: HTTPRequest, task: URLSessionTask, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust,
              isValid(trust: trust, forDomain: challenge.protectionSpace.host) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        completionHandler(.useCredential, URLCredential(trust: trust))
    }
    
    // MARK: - Public Functions

    open func isValid(trust: SecTrust, forDomain domain: String?) -> Bool {
        SecTrustSetPolicies(trust, trustPolicyForDomain(domain))

        if usePublicKeys {
            return isValidPublicKeys(trust: trust, domain: domain)
        } else if let certificates = self.certificates {
            return isValidCertificates(certificates, trust: trust, domain: domain)
        } else {
            return false
        }
    }
        
    // MARK: - Private Functions

    /// Creste SecPolicy for given domain.
    ///
    /// - Parameter domain: domain.
    /// - Returns: SecPolicy
    private func trustPolicyForDomain(_ domain: String?) -> SecPolicy {
        switch validatedDomainName {
        case true:
            return SecPolicyCreateSSL(true, domain as CFString?)
        case false:
            return SecPolicyCreateBasicX509()
        }
    }
    
    private func isValidCertificates(_ certs: [Data], trust: SecTrust, domain: String?) -> Bool {
        let serverCerts = trust.certificateChain()
        
        let collect: [SecCertificate] = certs.map {
            SecCertificateCreateWithData(nil, $0 as CFData)!
        }
        
        SecTrustSetAnchorCertificates(trust,collect as CFArray)
        var result: SecTrustResultType = SecTrustResultType(rawValue: UInt32(0))!
        if SecTrustEvaluateWithError(trust, nil) == false {
            result = .fatalTrustFailure
        }
        
        guard result == .unspecified || result == .proceed else {
            return false
        }
        
        var trustedCount = 0
        for serverCert in serverCerts {
            for cert in certs {
                if cert == serverCert {
                    trustedCount += 1
                    break
                }
            }
        }
        return (trustedCount == serverCerts.count)
    }
    
    private func isValidPublicKeys(trust: SecTrust, domain: String?) -> Bool {
        guard let keys = publicKeys else {
            return false
        }
        
        var trustedCount = 0
        let serverPubKeys = trust.publicKeyChain()
        for serverKey in serverPubKeys as [AnyObject] {
            for key in keys as [AnyObject] {
                if serverKey.isEqual(key) {
                    trustedCount += 1
                    break
                }
            }
        }
        
        return (trustedCount == serverPubKeys.count)
    }
    
}

// MARK: - Data Extension

fileprivate extension Data {
    
    /// Extract the public key from a Data which contains a certificate.
    ///
    /// - Returns: SecKey?
    func extractPublicKey() -> SecKey? {
        let possibleCert = SecCertificateCreateWithData(nil, self as CFData)
        return possibleCert?.extractPublicKeyFromCert(policy: SecPolicyCreateBasicX509())
    }
    
}

// MARK: - SecTrust Extension

fileprivate extension SecTrust {
    
    /// Get the public key chain for the trust instance.
    /// - Returns: [SecKey]
    func publicKeyChain() -> [SecKey] {
        let policy = SecPolicyCreateBasicX509()
        let list: [SecKey] = (0..<SecTrustGetCertificateCount(self)).compactMap { index in
            let cert = SecTrustGetCertificateAtIndex(self, index)
            guard let key = cert?.extractPublicKeyFromCert(policy: policy) else {
                return nil
            }
            return key
        }
        return list
    }
    
    /// Get the certificate chain for the trust.
    /// - Returns: [Data]
    func certificateChain() -> [Data] {
        (0..<SecTrustGetCertificateCount(self)).map { index in
            let cert = SecTrustGetCertificateAtIndex(self, index)
            return SecCertificateCopyData(cert!) as Data
        }
    }
    
}

// MARK: - SecCertificate Extension

fileprivate extension SecCertificate {
    
    /// Get the public key from a certificate data
    ///
    /// - Parameter policy: policty to use.
    /// - Returns: SecKey
    func extractPublicKeyFromCert(policy: SecPolicy) -> SecKey? {
        var possibleTrust: SecTrust?
        SecTrustCreateWithCertificates(self, policy, &possibleTrust)
        if let trust = possibleTrust {
            let evaluates = (SecTrustEvaluateWithError(trust, nil));
            guard evaluates else {
                return nil
            }
            return SecTrustCopyPublicKey(trust)
        }
        
        return nil
    }
    
}
