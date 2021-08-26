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
    public typealias RetryRequestProvider = ((_ request: HTTPRequestProtocol, _ response: HTTPRawResponse) -> HTTPRequestProtocol)
    
    // MARK: - Public Properties
    
    /// Trigger codes.
    open var triggerHTTPCodes: Set<HTTPStatusCode>
    
    /// Provider of the request.
    open var requestProvider: RetryRequestProvider
    
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
    
    // MARK: - Protocol Conformance
    
    open func validate(response: HTTPRawResponse, forRequest request: HTTPRequestProtocol) -> HTTPResponseValidatorResult {
        guard let statusCode = response.error?.statusCode, triggerHTTPCodes.contains(statusCode) else {
            return .passed
        }
        
        // If error is one of the errors in `triggerHTTPCodes`
        let altOperation = requestProvider(request, response)
        return .retryAfter(altOperation)
    }
    
}
