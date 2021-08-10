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

// MARK: - HTTPResponseValidator

/// The action to execute with validator.
///
/// - `failWithError`: call fails with given error.
/// - `retryIfPossible`: retry the call; this action may be ignored if source HTTPRequest does not allows retry or
///                      the maximum amount of retries has been reached yet.
/// - `retryAfter`: attempt to execute another request, then the current one
///                 (ie. session is expired and a silent login must be accomplished
///                 before re-trying the current request).
/// - `passed`: validation is passed, nothing to do.
public enum HTTPResponseValidatorAction {
    case failWithError(Error)
    case retryIfPossible
    case retryAfter(HTTPRequestProtocol)
    case passed
}

// MARK: - HTTPResponseValidator

/// Validatation of the responses.
public protocol HTTPResponseValidator {
    
    /// Validate the reponse of an HTTP operation and execute specified action.
    ///
    /// - Parameter response: response to read.
    func validate(response: HTTPRawResponse) -> HTTPResponseValidatorAction
    
}
