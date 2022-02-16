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

/// This validator can be used to provide an alternate request operation to execute before
/// retry the initial request. It may be used to provide silent login operation when you receive
/// and authorized/forbidden errors.
/// It's triggered by the `triggerHTTPCodes` which by default is set `.unathorized, .forbidden`.
open class HTTPAltRequestValidator: HTTPResponseValidatorProtocol {
    public typealias RetryRequestProvider = ((_ request: HTTPRequestProtocol, _ response: HTTPRawResponse) -> HTTPRequestProtocol?)
    
    // MARK: - Public Properties
    
    /// Trigger codes.
    open var triggerHTTPCodes: Set<HTTPStatusCode>
    
    /// Provider of the request.
    open var requestProvider: RetryRequestProvider
    
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
    
    open func validate(response: HTTPRawResponse, forRequest request: HTTPRequestProtocol) -> HTTPResponseValidatorResult {
        if let statusCode = response.error?.statusCode, triggerHTTPCodes.contains(statusCode) {
            return .passed
        }
        
        // If error is one of the errors in `triggerHTTPCodes`
        
        // If we reached the maximum number of alternate calls to execute we want to cancel any other attempt.
        if let maxAltRequestsToExecute = maxAltRequestsToExecute,
              numberOfAltRequestExecuted > maxAltRequestsToExecute {
            let error = HTTPError(.maxRetryAttemptsReached)
            return .failWithError(error)
        }
        
        guard let altOperation = requestProvider(request, response) else {
            return .passed // if no retry operation is provided we'll skip and mark the validation as passed
        }

        numberOfAltRequestExecuted += 1
        return .retryAfter(altOperation)
    }
    
}
