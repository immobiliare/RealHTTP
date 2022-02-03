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
public protocol HTTPSecurityService {
        
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
