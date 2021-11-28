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

// MARK: - HTTPResponseValidatorResult

/// The action to execute with validator.
///
/// - `failWithError`: call fails with given error.
/// - `retryIfPossible`: retry the call; this action may be ignored if source HTTPRequest does not allows retry or
///                      the maximum amount of retries has been reached yet.
/// - `retryWithInterval`: retry the call after a given specified time interval (in seconds)
/// - `retryAfter`: attempt to execute another request, then the current one
///                 (ie. session is expired and a silent login must be accomplished
///                 before re-trying the current request).
/// - `passed`: validation is passed, nothing to do.
public enum HTTPResponseValidatorResult {
    case failWithError(Error)
    case retryIfPossible
    case retryWithInterval(TimeInterval)
    case retryAfter(HTTPRequestProtocol)
    case passed
}

// MARK: - HTTPResponseValidatorProtocol

/// Validatation of the responses.
public protocol HTTPResponseValidatorProtocol {
    
    /// Validate the reponse of an HTTP operation and execute specified action.
    /// - Parameters:
    ///   - response: response to validate.
    ///   - request: origin request.
    func validate(response: HTTPRawResponse, forRequest request: HTTPRequestProtocol) -> HTTPResponseValidatorResult
    
}

// MARK: - HTTPCustomValidator

/// A shortcut struct to append on-the-fly response validator.
public struct HTTPCustomValidator: HTTPResponseValidatorProtocol {

    // MARK: - Public Properties

    public typealias Handler = (HTTPRawResponse, HTTPRequestProtocol) -> HTTPResponseValidatorResult
    
    /// Identifier of the validator.
    public let name: String?
    
    // MARK: - Private Properties
    
    /// Handler function.
    private let handler: Handler
    
    // MARK: - Initialization
    
    /// Initialize a new wrapper to contain validation function.
    ///
    /// - Parameters:
    ///   - name: name of the wrapper (it's just for your own needs).
    ///   - handler: handler validation function
    public init(name: String?, _ handler: @escaping Handler) {
        self.name = name
        self.handler = handler
    }
    
    // MARK: - Conformance
    
    public func validate(response: HTTPRawResponse, forRequest request: HTTPRequestProtocol) -> HTTPResponseValidatorResult {
        handler(response,request)
    }
    
}
