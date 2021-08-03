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

// MARK: - HTTPStandardValidator

open class HTTPStandardValidator: HTTPResponseValidator {
    
    // MARK: - Public Properties
    
    /// If `true` empty responses are tracked as valid responses if status code it's not an error.
    /// In case of empty response validation fails with `emptyResponse` error.
    public var allowsEmptyResponses: Bool = true
    
    // MARK: - Validation
    
    /// Validate the response and set the action to perform.
    ///
    /// - Parameter response: response received.
    /// - Returns: HTTPResponseValidatorAction
    open func validate(response: HTTPRawResponse) -> HTTPResponseValidatorAction {
        if let error = response.error {
            if allowsRetryForError(error) {
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
        
        if !allowsEmptyResponses && (response.data?.isEmpty ?? true) {
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
    open func allowsRetryForError(_ error: Error) -> Bool {
        if let x = error as? HTTPError {
            return x.statusCode == .unauthorized
        }
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

// MARK: - HTTPError (URLResponse)

extension HTTPError {
    
    /// Parse the response of an HTTP operation and return `nil` if no error has found,
    /// a valid `HTTPError` if call has failed.
    ///
    /// - Parameter httpResponse: response from http layer.
    /// - Returns: HTTPError?
    public static func fromHTTPResponse(response: URLResponse?, data: Data?, error: Error?) -> HTTPError? {
        // If HTTP is an error or an error has received we can create the error object
        let httpCode = HTTPStatusCode(URLResponse: response) ?? .none
        let isError = (error != nil || httpCode.responseType != .success)
        
        guard isError else {
            return nil
        }
        
        // Evaluate error kind
        let cocoaErrorCode = (error as NSError?)?.code
        let userInfo = (error as NSError?)?.userInfo
        let isConnectionError = error?.isConnectionError ?? false
        let errorType: HTTPError.ErrorType = (isConnectionError ? .connectionError : .network)
        
        return HTTPError(errorType,
                         code: httpCode,
                         error: error,
                         userInfo: userInfo,
                         cocoaCode: cocoaErrorCode)
    }
    
}
