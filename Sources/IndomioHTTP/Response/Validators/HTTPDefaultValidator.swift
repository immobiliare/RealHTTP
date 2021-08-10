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

/// This is the default HTTP validator used to validate the request. You can use
/// it as is or subclass to make your own validator.
/// 
/// This validator allows you to configure:
/// - Allows/Deny Empty responses: to allows or generate an error in case of empty response by server.
/// - Configure Retry Policy: allows you to configure what kind of `Error` should trigger a retry attempt for request.
open class HTTPDefaultValidator: HTTPResponseValidator {
    
    // MARK: - Public Properties
    
    /// If `true` empty responses are tracked as valid responses if status code it's not an error.
    /// In case of empty response validation fails with `emptyResponse` error.
    public var allowsEmptyResponses = true
    
    // MARK: - Validation
    
    /// Validate the response and set the action to perform.
    ///
    /// - Parameter response: response received.
    /// - Returns: HTTPResponseValidatorAction
    open func validate(response: HTTPRawResponse) -> HTTPResponseValidatorAction {
        if let error = response.error {
            if shouldAllowRetryWithError(error) {
                // Some errors allows retry of the call.
                // Retry option is managed by the HTTPRequest itself (if we reached the
                // maximum amount of retries or no retries are allowed by request this
                // request will be ignored).
                return .retryIfPossible
            } else {
                // Some other fails
                return .failWithError(error)
            }
        }
        
        if !allowsEmptyResponses && (response.content?.data?.isEmpty ?? true) {
            // If empty response are not allowed it fails with `.emptyResponse` code.
            return .failWithError(HTTPError(.emptyResponse))
        }
        
        return .passed
    }
    
    /// Return `true` if error received should allow retry of the call.
    ///
    /// At the lowest network levels, it makes sense to retry for cases of temporary outage.
    /// Things like timeouts, can't connect to host, network connection lost.
    ///
    /// - Parameter error: error received.
    /// - Returns: Bool
    open func shouldAllowRetryWithError(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else {
            return false
        }
        
        switch urlError.code {
            case URLError.timedOut,
                 URLError.cannotFindHost,
                 URLError.cannotConnectToHost,
                 URLError.networkConnectionLost,
                 URLError.dnsLookupFailed:
                return true
                
            default:
                return false
        }
    }
    
}
