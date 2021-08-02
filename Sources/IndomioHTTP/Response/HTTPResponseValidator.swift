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
/// - `retryAfter`: attempt to execute another request, then the current one
///                 (ie. session is expired and a silent login must be accomplished
///                 before re-trying the current request).
/// - `passed`: validation is passed, nothing to do.
public enum HTTPResponseValidatorAction {
    case failWithError(Error)
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

public struct HTTPStandardValidator: HTTPResponseValidator {
    
    // MARK: - Public Properties
    
    /// If `true` empty responses are tracked as valid responses if status code it's not an error.
    public var allowsEmptyResponses: Bool = true
    
    // MARK: - Validation
    
    public func validate(response: HTTPRawResponse) -> HTTPResponseValidatorAction {
        if let error = response.error {
            return .failWithError(error)
        }
        
        return .passed
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
