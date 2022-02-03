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

/// This validator can be used to provide an alternate request operation to execute before
/// retry the initial request. It may be used to provide silent login operation when you receive
/// and authorized/forbidden errors.
/// It's triggered by the `triggerHTTPCodes` which by default is set `.unathorized, .forbidden`.
open class HTTPAltRequestValidator: HTTPValidator {
    public typealias RetryRequestProvider = ((_ request: HTTPRequest, _ response: HTTPResponse) -> HTTPRequest?)
    
    // MARK: - Public Properties
    
    /// Trigger codes.
    open var triggerHTTPCodes: Set<HTTPStatusCode>
    
    /// Provider of the request.
    open var requestProvider: RetryRequestProvider
    
    /// This allows you to observe the response of the alt request executed
    /// and perform your own logic before retry the initial call failed.
    ///
    /// For example if your strategy is to try a silent login in your
    /// alt request you can use this method setup received response with
    /// the token as your session cookies so when the initial call is retried
    /// everything will be okay.
    open var altRequestCatcher: HTTPRetryStrategy.AltRequestCatcher?
    
    /// This is the delay to retry the initial request after the alt request
    /// has been executed. By default is 0s.
    open var retryMainCallDelay: TimeInterval = 0
    
    /// Number of alternate calls to execute.
    /// By default is set to 1. It means the first alternate call which fails on a certain
    /// request will fails any other request in the same session.
    open var maxAltRequestsToExecute: Int? = nil
    
    // MARK: - Private Properties
    
    /// Number of executed alternate request.
    private var numberOfAltRequestExecuted = 0
    
    // MARK: - Initialization
    
    /// Initialize to provide a new request when a code is triggered.
    /// The alternate request is executed in case of triggered errors, then the original request is re-executed.
    ///
    /// - Parameters:
    ///   - triggerCodes: trigger http codes, by default `[.unauthorized, .forbidden]`.
    ///   - requestProvider: provider of the alternate request to execute.
    public init(triggerCodes: Set<HTTPStatusCode> = [.unauthorized, .forbidden],
                _ requestProvider: @escaping RetryRequestProvider) {
        self.triggerHTTPCodes = triggerCodes
        self.requestProvider = requestProvider
    }
    
    /// Reset the state of alt requests executed.
    public func reset() {
        numberOfAltRequestExecuted = 0
    }
    
    // MARK: - Protocol Conformance
    
    public func validate(response: HTTPResponse, forRequest request: HTTPRequest) -> HTTPResponseValidatorResult {
        if let statusCode = response.error?.statusCode, triggerHTTPCodes.contains(statusCode) {
            return .nextValidator
        }
        
        // If error is one of the errors in `triggerHTTPCodes`
        
        // If we reached the maximum number of alternate calls to execute we want to cancel any other attempt.
        numberOfAltRequestExecuted += 1
        if let maxAltRequestsToExecute = maxAltRequestsToExecute,
              numberOfAltRequestExecuted > maxAltRequestsToExecute {
            let error = HTTPError(.maxRetryAttemptsReached)
            return .failChain(error)
        }
        
        guard let altOperation = requestProvider(request, response) else {
            return .nextValidator // if no retry operation is provided we'll skip and mark the validation as passed
        }
        
        return .retry(.after(altOperation, retryMainCallDelay, altRequestCatcher))
    }
    
}
