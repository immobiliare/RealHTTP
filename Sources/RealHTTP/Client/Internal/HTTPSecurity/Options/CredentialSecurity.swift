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

/// This a concrete class of the `CredentialSecurity` which allows you to perform
/// authenticated session using the `URLSession`'s `URLAuthenticationChallenge`.
public struct CredentialSecurity: HTTPSecurityService {
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
    
    public func receiveChallenge(_ challenge: URLAuthenticationChallenge, forRequest request: HTTPRequest, task: URLSessionTask, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let cred = callback(challenge) else {
            completionHandler(.rejectProtectionSpace, nil)
            return
        }
        
        completionHandler(.useCredential, cred)
    }
    
}
