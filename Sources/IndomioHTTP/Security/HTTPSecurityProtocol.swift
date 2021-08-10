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

public protocol HTTPSecurityProtocol {
        
    /// Receive challange for authentication.
    ///
    /// - Parameters:
    ///   - challenge: challange.
    ///   - request: request.
    ///   - task: task associated with request.
    ///   - completionHandler: completion handler.
    func receiveChallenge(_ challenge: URLAuthenticationChallenge,
                          forRequest request: HTTPRequestProtocol, task: URLSessionTask,
                          completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)

    
}
