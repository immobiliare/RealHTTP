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

/// HTTPSecurity is used to make SSL pinning.
open class HTTPSecurity {
    
    // MARK: - Public Properties

    /// Should the domain name be validated?
    open var validatedDomainName = true
    
    /// The certificates.
    var certificates: [Data]? //the certificates
    
    /// The public keys
    var pubKeys: [SecKey]? //the public keys
    
    /// Use pu
    var usePublicKeys = false //use public keys or certificate validation?
    
    // MARK: - Initialization
    
    /// Initialize a new HTTPSecurity instance with given certificates.
    ///
    /// - Parameters:
    ///   - certs: SSL Certificates to use.
    ///   - usePublicKeys: true to use public keys.
    public init(certs: [SSLCert], usePublicKeys: Bool) {
        self.usePublicKeys = usePublicKeys
        
        if self.usePublicKeys {
            self.pubKeys = certs.compactMap { cert in
                if let data = cert.certData , cert.publicKey == nil  {
                    cert.publicKey = data.extractPublicKey()
                }
                guard let publicKey = cert.publicKey else {
                    return nil
                }
                return publicKey
            }
        } else {
            self.certificates = certs.compactMap {
                $0.certData
            }
        }
    }
    
    /// Use certs from main app bundle.
    ///
    /// - Parameter usePublicKeys: s to specific if the publicKeys or certificates should be used for SSL pinning validation
    public convenience init(bundledIn directory: String = ".", usePublicKeys: Bool = false) {
        let fileURLs = Bundle.main.paths(forResourcesOfType: "cer", inDirectory: directory).map({
            URL(fileURLWithPath: $0 as String)
        })
        
        let certificates = SSLCert.fromFileURLs(fileURLs)
        self.init(certs: certificates, usePublicKeys: usePublicKeys)
    }
    
}
