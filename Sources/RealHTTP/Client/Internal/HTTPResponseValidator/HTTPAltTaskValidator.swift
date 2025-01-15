//
//  RealHTTP
//  Lightweight Async/Await Network Layer/Stubber for Swift
//
//  Created & Maintained by Mobile Platforms Team @ ImmobiliareLabs.it
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Created by: Daniele Margutti <hello@danielemargutti.com>

//  CONTRIBUTORS:
//  Thank you to all the contributors who made this project better:
//  <https://github.com/immobiliare/RealHTTP/graphs/contributors>
//
//  Copyright ©2022 Immobiliare.it SpA.
//  Licensed under MIT License.
//

import Foundation

/// This validator can be used to provide an alternate Task to execute before
/// retry the initial request. It may be used to provide silent login operation when you receive
/// and authorized/forbidden errors.
///
/// It's triggered by the `statusCodes` which by default is set `.unathorized, .forbidden`.
open class HTTPAltTaskValidator: HTTPValidator {
    public typealias RetryRequestProvider = ((_ request: HTTPRequest, _ response: HTTPResponse) -> HTTPRequest?)
    
    // MARK: - Public Properties (Configuration Options)
    
    /// HTTP status codes which trigger the validator callback.
    ///
    /// NOTE:
    /// If you want to trigger the no-response (ie. network failure) you should
    /// add `none` in triggered status code response.
    open var statusCodes: Set<HTTPStatusCode>
    
    /// This is the delay to retry the initial request after the alt request
    /// has been executed. By default is 0s.
    open var retryDelay: TimeInterval = 0
    
    /// Number of alternate calls to execute.
    /// By default is set to `nil`.
    /// It means the first alternate call which fails on a certain
    /// request will fails any other request in the same session.
    open var maxAltRequests: Int?
    
    /// The task to execute as an alternate operation.
    ///
    /// This task is expected to perform any action that would allow the request to be retried,
    /// such as re-authentication. This task must be asynchronous and may throw errors.
    open var alternativeTask: HTTPRetryStrategy.RetryTask?
    
    /// A closure that is invoked to handle errors encountered during the execution of the retry task.
    ///
    /// This closure allows the application to handle errors (such as login failure) before retrying the original request.
    open var taskErrorCatcher: HTTPRetryStrategy.RetryTaskErrorCatcher?
    
    // MARK: - Private Properties
    
    /// Number of executed alternate request.
    open var numberOfAltRequestExecuted = 0
    
    // MARK: - Initialization
    
    /// Initialize to provide a new request when one of `triggeredCodes` arrives.
    ///
    /// - Parameters:
    ///   - statusCodes: array of `HTTPStatusCode` which trigger the validator (default is `[.unauthorized, .forbidden]`)
    ///   - alternativeTask: The task to execute as an alternative operation (e.g., silent login).
    ///   - taskErrorCatcher: A closure to handle any errors that occur during the retry task.
    public init(statusCodes: Set<HTTPStatusCode> = [.unauthorized, .forbidden],
                alternativeTask: HTTPRetryStrategy.RetryTask? = nil,
                taskErrorCatcher: HTTPRetryStrategy.RetryTaskErrorCatcher? = nil) {
        self.statusCodes = statusCodes
        self.alternativeTask = alternativeTask
        self.taskErrorCatcher = taskErrorCatcher
    }
    
    // MARK: - Protocol Conformance
    
    open func validate(response: HTTPResponse, forRequest request: HTTPRequest) -> HTTPResponseValidatorResult {
        guard statusCodes.contains(response.statusCode) else {
            // if received status code for this request is not inside the triggerable status codes we'll skip the validator.
            return .nextValidator
        }
                        
        if let maxAltRequests = maxAltRequests, numberOfAltRequestExecuted >= maxAltRequests {
            // If we reached the maximum number of alternate calls to execute we want to cancel any other attempt.
            return .failChain(HTTPError(.retryAttemptsReached))
        }

        // if no retry operation is provided we'll skip and mark the validation as passed
        guard let alternativeTask = alternativeTask else {
            return .nextValidator
        }
        
        // Perform the alt request strategy.
        numberOfAltRequestExecuted += 1
        return .retry(.afterTask(retryDelay, alternativeTask, taskErrorCatcher))
    }
    
}
