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

/// Parameters for an `HTTPRequestProtocol`
public typealias HTTPURLRequestModifierCallback = ((inout URLRequest) throws -> Void)
public typealias HTTPRequestParametersDict = [String: AnyObject]
public typealias HTTPParameters = [String: Any]

// MARK: - HTTPRequestProtocol

/// Generic protocol which describe a request.
public protocol HTTPRequestProtocol: AnyObject {
    typealias HTTPResponseCallback = ((Result<Data, Error>) -> Void)
    typealias DataResultCallback = ((HTTPRawResponse) -> Void)

    // MARK: - Public Properties
    
    /// Current state of the request (not thread-safe)
    var state: HTTPRequestState { get }
    
    /// Thread safe value which identify if a request in pending state or not.
    var isPending: Bool { get }
    
    /// Path to the endpoint. URL is composed along the `baseURL` of the `HTTPClient`
    /// instance where the request is running into.
    var route: String { get set }
    
    /// Method to be used as request.
    var method: HTTPMethod { get set }
    
    /// Headers to send with the request. These values are combined with
    /// the default's `HTTPClient` used with the precedence on request's keys.
    var headers: HTTPHeaders { get set }
    
    /// Parameters to encode onto the request.
    var queryParameters: URLParametersData? { get set }
    
    /// Body content.
    var content: HTTPRequestEncodableData? { get set }
    
    /// Timeout interval for request. When `nil` no timeout is set. This override the
    /// `HTTPClient` instance's `timeout`.
    var timeout: TimeInterval? { get set }
    
    /// The cache policy for the request. Defaults parent `HTTPClient` setting.
    var cachePolicy: URLRequest.CachePolicy? { get set }
    
    /// Maximum number of retries to set.
    var maxRetries: Int { get set }
    
    /// Current retry attempt. 0 is the first attempt.
    var currentRetry: Int { get set }
    
    /// This method is called right after the `URLRequest`associated with the object is created
    /// and before it's executed by the client. You can use it in order to modify some settings.
    var urlRequestModifier: HTTPURLRequestModifierCallback? { get set }
    
    // MARK: - Initialization
    
    /// Initialize a new request with given parameters.
    ///
    /// - Parameters:
    ///   - method: HTTP method for the request, by default is `.get`.
    ///   - route: route to compose with the base url of the `HTTPClient` where the request is running.
    init(method: HTTPMethod, route: String)
    
    // MARK: - Public Functions
    
    /// Create the underlying `URLRequest` instance for an `HTTPRequestProtocol` running into a `HTTPClient` instance.
    ///
    /// - Parameters:
    ///   - request: request.
    ///   - client: client in which the request should run.
    func urlRequest(in client: HTTPClient) throws -> URLRequest
    
    // MARK: - Execution
    
    /// Execute a call (if needed) and get the raw response.
    ///
    /// - Parameters:
    ///   - queue: queue in which the call is executed, `nil` to use the same queue of the caller.
    ///   - callback: callback.
    @discardableResult
    func rawResponse(in queue: DispatchQueue?, _ callback: @escaping DataResultCallback) -> Self
    
    // MARK: - Private
    
    /// Called when a response from client did received.
    /// NOTE: You should never call it directly.
    ///
    /// - Parameters:
    ///   - response: response.
    ///   - client: client.
    func receiveResponse(_ response: HTTPRawResponse, client: HTTPClient)

        
    /// Reset the request by removing any downloaded data or error.
    ///
    /// - Parameter retries: `true` to also reset retries attempts.
    func reset(retries: Bool)
    
}

// MARK: - HTTPRequestState

/// Defines the state of the request.
/// - `pending`: request has never executed, no response is available.
/// - `executing`: request is currently in progress.
/// - `finished`: request is finished and result is available.
public enum HTTPRequestState {
    case pending
    case executing
    case finished
}
