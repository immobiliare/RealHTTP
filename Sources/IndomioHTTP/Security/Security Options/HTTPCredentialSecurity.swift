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

public struct HTTPCredentialSecurity: HTTPSecurityProtocol {
    public typealias AuthenticationCallback = ((URLAuthenticationChallenge) -> URLCredential?)
    
    // MARK: - Public Properties
    
    /// Callback for credentials based authorization.
    public var callback: AuthenticationCallback
    
    // MARK: - Initialization
    
    /// Initialize a new credentials security with callback for authentication.
    ///
    /// - Parameter callback: callback.
    public init(_ callback: @escaping AuthenticationCallback) {
        self.callback = callback
    }
    
    // MARK: - Conformance
    
    public func receiveChallenge(_ challenge: URLAuthenticationChallenge, forRequest request: HTTPRequestProtocol, task: URLSessionTask, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard let cred = callback(challenge) else {
            completionHandler(.rejectProtectionSpace, nil)
            return
        }
        
        completionHandler(.useCredential, cred)
    }
    
}
