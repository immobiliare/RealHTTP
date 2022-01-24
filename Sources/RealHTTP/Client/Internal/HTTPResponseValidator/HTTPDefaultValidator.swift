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
    open var allowsEmptyResponses = true
    
    /// If status code is in this list call could be retry again.
    /// Dictionary optionally specify an interval (expressed in seconds) to retry
    /// the same call. Use `0` to immediately retry it.
    ///
    /// Default implementation allows retry for:
    /// - `HTTP 429` (Too Many Request): 3 seconds
    open var retriableHTTPStatusCodes: [HTTPStatusCode: TimeInterval] = [
        .tooManyRequests: 3 // wait 3 seconds before retry the call.
    ]
    
    // MARK: - Initialization
    
    /// Initialize a new validator.
    public init() {
    
    }
    
    // MARK: - Validation
    
    /// Validate the response and set the action to perform.
    ///
    /// - Parameters:
    ///   - response: response.
    ///   - request: origin request.
    /// - Returns: HTTPResponseValidatorAction
    ///
    open func validate(response: HTTPResponse, forRequest request: HTTPRequest) -> HTTPResponseValidatorResult {
        if let error = response.error,
           let allowedRetryMode = allowedRetry(forResponse: response, error: error) {
            // Some errors allows retry of the call.
            // Retry option is managed by the HTTPRequest itself (if we reached the
            // maximum amount of retries or no retries are allowed by request this
            // request will be ignored).
            return allowedRetryMode
        }
        
        if !allowsEmptyResponses && (response.data?.isEmpty ?? true) {
            // If empty response are not allowed it fails with `.emptyResponse` code.
            return .failChain(HTTPError(.emptyResponse))
        }
        
        return .nextValidator
    }
    
    /// Return `true` if error received should allow retry of the call.
    ///
    /// At the lowest network levels, it makes sense to retry for cases of temporary outage.
    /// Things like timeouts, can't connect to host, network connection lost.
    ///
    /// - Parameters:
    ///   - response: response received.
    ///   - error: error received.
    /// - Returns: `HTTPResponseValidatorResult` or `nil` if retry is not supported
    open func allowedRetry(forResponse response: HTTPResponse, error: Error) -> HTTPResponseValidatorResult? {
        // If error is part of retriable http status code we want to try again the call.
        if let retryInterval = retriableHTTPStatusCodes[response.statusCode] {
            return .retry(.delayed(retryInterval))
        }
        
        guard let urlError = error as? URLError else {
            return nil
        }
        
        switch urlError.code {
            case URLError.timedOut,
                 URLError.cannotFindHost,
                 URLError.cannotConnectToHost,
                 URLError.networkConnectionLost,
                 URLError.dnsLookupFailed:
            return .retry(.immediate)
                
            default:
                return nil
        }
    }
    
}
