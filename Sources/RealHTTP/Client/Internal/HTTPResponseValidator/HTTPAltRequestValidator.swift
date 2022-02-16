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
///
/// It's triggered by the `statusCodes` which by default is set `.unathorized, .forbidden`.
open class HTTPAltRequestValidator: HTTPValidator {
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
    /// By default is set to 1.
    /// It means the first alternate call which fails on a certain
    /// request will fails any other request in the same session.
    open var maxAltRequests = 1
    
    // MARK: - Public Properties (Observable Events)
    
    /// This callback is called when validator ask to you to provide the
    /// alternate request to execute before retry the initial failed call.
    open var onProvideAltRequest: RetryRequestProvider
    
    /// This callback is called when the alternate request did finish and
    /// you want to read and so something with the response.
    /// This is an async call you can use to perform your own logic before
    /// the initial call is retried automatically.
    ///
    /// For example if your strategy is to try a silent login in your
    /// alt request you can use this method setup received response with
    /// the token as your session cookies so when the initial call is retried
    /// everything will be okay.
    open var onReceiveAltResponse: HTTPRetryStrategy.AltRequestCatcher?
    
    // MARK: - Private Properties
    
    /// Number of executed alternate request.
    private var numberOfAltRequestExecuted = 0
    
    // MARK: - Initialization
    
    /// Initialize to provide a new request when one of `triggeredCodes` arrives.
    ///
    /// - Parameters:
    ///   - statusCodes: array of `HTTPStatusCode` which trigger the validator (default is `[.unauthorized, .forbidden]`)
    ///   - onProvideAltRequest: the function which ask what alternate request you want
    ///                          to execute when a initial request is received
    ///   - onReceiveAltResponse: use this callback to catch the response received by the alt request and perform your logic.
    public init(statusCodes: Set<HTTPStatusCode> = [.unauthorized, .forbidden],
                onProvideAltRequest: @escaping RetryRequestProvider,
                onReceiveAltResponse: HTTPRetryStrategy.AltRequestCatcher?) {
        self.statusCodes = statusCodes
        self.onProvideAltRequest = onProvideAltRequest
        self.onReceiveAltResponse = onReceiveAltResponse
    }
    
    // MARK: - Public Functions
    
    /// Reset the state of alt requests executed.
    public func reset() {
        numberOfAltRequestExecuted = 0
    }
    
    // MARK: - Protocol Conformance
    
    public func validate(response: HTTPResponse, forRequest request: HTTPRequest) -> HTTPResponseValidatorResult {
        guard statusCodes.contains(response.statusCode) else {
            // if received status code for this request is not inside the triggerable status codes we'll skip the validator.
            return .nextValidator
        }
                        
        if numberOfAltRequestExecuted > maxAltRequests {
            // If we reached the maximum number of alternate calls to execute we want to cancel any other attempt.
            return .failChain(HTTPError(.maxRetryAttemptsReached))
        }

        // if no retry operation is provided we'll skip and mark the validation as passed
        guard let altOperation = onProvideAltRequest(request, response) else {
            return .nextValidator
        }
        
        // Perform the alt request strategy.
        numberOfAltRequestExecuted += 1
        return .retry(.after(altOperation, retryDelay, onReceiveAltResponse))
    }
    
}
