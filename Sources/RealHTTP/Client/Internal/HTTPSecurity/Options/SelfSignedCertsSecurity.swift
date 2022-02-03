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

/// You can use the following security options to auto-accept any self-signed
/// certificate. This is particularly useful when you are in a development
/// environment where certificates maybe not signed by any cert authority.
///
/// IMPORTANT:
/// This is useful for debug purpose: don't use it on production.
public struct SelfSignedCertsSecurity: HTTPSecurityService {
    
    public func receiveChallenge(_ challenge: URLAuthenticationChallenge, forRequest request: HTTPRequest, task: URLSessionTask, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.useCredential, nil)
            return
        }
        
        completionHandler(.useCredential, URLCredential(trust: trust))
    }
    
}
