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

// MARK: - HTTPResponseValidator

/// This is a generic protocol you can adopt to create and set validators for data
/// received by an `HTTPClient` instance.
public protocol HTTPValidator {
    
    /// Validate the reponse of an HTTP operation and execute specified action.
    /// - Parameters:
    ///   - response: response to validate.
    ///   - request: origin request.
    func validate(response: HTTPResponse, forRequest request: HTTPRequest) -> HTTPResponseValidatorResult
    
}

// MARK: - HTTPResponseValidatorResult

/// Result of validation. It's used to perform additional actions:
/// - `failChain`: fail validaton chain reporting with given error.
/// - `retry`: retry - if possible - with set strategy.
/// - `nextValidator`: operation succeded, move to next validator or complete all.
/// - `nextValidatorWithResponse`: operation succeded, move to the next validator by passing a modified version of the response received.
///                                this can be useful when you need to sightly modify or return a subclass version of the original response.
public enum HTTPResponseValidatorResult {
    case failChain(Error)
    case retry(HTTPRetryStrategy)
    case nextValidator
    case nextValidatorWithResponse(HTTPResponse)
}

// MARK: - HTTPRetryStrategy

/// Retry strategy when operation did fails.
/// - `immediate`: retry immediately with a maximum number of attempts.
/// - `delayed`: retry call after a given interval with a maximum number of attempts.
/// - `exponential`: retry call with an exponential interval depending of the current attempt.
/// - `fibonacci`: retry with an interval evaluated with fibonacci depending of the current attempt.
/// - `after`: retry after executing (successfully) another request.
///            parameters are:
///              - the request you want to execute before retry the original request.
///              - the amount of time before retry the original request once you got the response for the alt request.
///              - an optional async callback to execute once you got the response of the alt request before retry the original request.
public enum HTTPRetryStrategy {
    public typealias AltRequestCatcher = ((_ request: HTTPRequest, _ response: HTTPResponse) async throws -> Void)
    public typealias RetryTask = ((_ originalRequest: HTTPRequest) async throws -> Void)
    public typealias RetryTaskErrorCatcher = ((_ error: Error) async -> Void)
    
    case immediate
    case delayed(_ interval: TimeInterval)
    case exponential(_ base: Int)
    case fibonacci
    case after(HTTPRequest, TimeInterval, AltRequestCatcher?)
    case afterTask(TimeInterval, RetryTask, RetryTaskErrorCatcher?)
    
    // MARK: - Internal Functions
    
    /// Return the amount of time to wait before executing a retry depending the request's max attempts and current attempt.
    ///
    /// - Parameter request: request to execute.
    /// - Returns: `TimeInterval`
    internal func retryInterval(forRequest request: HTTPRequest) -> TimeInterval {
        let numberOfPreviousAttempts = request.currentRetry
        let maximumNumberOfAttempts = request.maxRetries
        
        switch self {
        case .immediate:
            return 0
            
        case .delayed(let interval):
            return interval
            
        case .exponential(let base):
            guard numberOfPreviousAttempts < maximumNumberOfAttempts else { return 0 }
            return pow(Double(base), Double(numberOfPreviousAttempts - 1))
            
        case .fibonacci:
            // swiftlint:disable identifier_name
            func fibonacci(n: Int) -> Int {
                switch n {
                case ...0: return 0
                case 1: return 1
                default: return fibonacci(n: n - 2) + fibonacci(n: n - 1)
                }
            }
            return Double(fibonacci(n: numberOfPreviousAttempts))
            
        case .after:
            return 0

        case .afterTask:
            return 0
        }
    }
    
}
