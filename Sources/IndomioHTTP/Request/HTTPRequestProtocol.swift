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
    
    /// Type of data expected which is used to define how it should managed from
    /// the `URLSession` subclass to use.
    var expectedDataType: HTTPExpectedDataType { get }
    
    /// If task is monitorable (`expectedDataType` is `large`) and data is available
    /// here you can found the latest progress stats.
    var progress: HTTPProgress? { get }
    
    /// If you are downloading large amount of data and you need to resume it
    /// you can specify a valid URL where data is saved and resumed.
    /// This location is used when `expectedDataType` is set to `large`.
    /// If no value has set a default location inside a subfolder in documents
    /// directory is used instead.
    var resumeDataURL: URL? { get }
    
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
    
    /// Allows you to set the proper security authentication methods.
    /// If not set the parent's client is used instead.
    var security: HTTPSecurityProtocol? { get set }
    
    /// This method is called right after the `URLRequest`associated with the object is created
    /// and before it's executed by the client. You can use it in order to modify some settings.
    var urlRequestModifier: HTTPURLRequestModifierCallback? { get set }
    
    /// Observers registered for raw data responses.
    var responseObservers: EventObserver<HTTPRawResponse> { get }
    
    /// Describe the priority of the operation.
    /// It may acts as a suggestion for HTTP/2 based services (priority frames / dependency weighting)
    /// for simple `HTTPClient` instances.
    /// In case of `HTTPQueueClient` it also act as priority level for queue concurrency.
    var priority: HTTPRequestPriority { get set }
    
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
    func urlRequest(in client: HTTPClientProtocol) throws -> URLRequest
    
    // MARK: - Execution
    
    /// Execute a call (if needed) and get the raw response.
    ///
    /// - Parameters:
    ///   - queue: queue in which the call is executed, `nil` to use the same queue of the caller.
    ///   - callback: callback.
    @discardableResult
    func setResponse(_ queue: DispatchQueue, _ callback: @escaping DataResultCallback) -> Self
    
    // MARK: - Private
    
    /// Called when a response from client did received.
    /// NOTE: You should never call it directly.
    ///
    /// - Parameters:
    ///   - response: response.
    ///   - client: client.
    func receiveHTTPResponse(_ response: HTTPRawResponse, client: HTTPClientProtocol)
    
    /// Called when progress of upload/download is running.
    ///
    /// - Parameter progress: state of the operation.
    func receiveHTTPProgress(_ progress: HTTPProgress)
    
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

// MARK: - HTTPExpectedDataType

/// Describe what kind of data you are expecting from the server for a response.
/// This used to identify what kind of `URLSessionTask` subclass we should use.
///
/// - `default`:  Data tasks are intended for short, often interactive requests from your app to a server.
///               Data tasks can return data to your app one piece at a time after each piece of data is received,
///               or all at once through a completion handler.
///               Because data tasks do not store the data to a file, they are not supported in background sessions.
/// - `large`: Directly writes the response data to a temporary file.
///            It supports background downloads when the app is not running.
///            Download tasks retrieve data in the form of a file, and support background downloads while the app is not running.
public enum HTTPExpectedDataType {
    case `default`
    case large
}

// MARK: - HTTPRequestPriority

/// Allows you to define the priority of request.
/// It acts different based upon the HTTPClient instance used.
///
/// For a simple `HTTPClient` it acts as an hint to the receiver host.
/// In this case it's a wrapper to HTTP/2 priority frames / dependency weighting
/// See:
/// <https://developer.apple.com/forums/thread/48371>
/// <http://www.ietf.org/rfc/rfc7540.txt>)
///
/// For `HTTPQueueClient` it also set the priority of the underlying queue and
/// works as priority level for both client and server side.
public enum HTTPRequestPriority {
    case veryLow
    case low
    case normal
    case high
    case veryHigh
    
    // MARK: - Internal Properties
    
    internal var queuePriority: Operation.QueuePriority {
        switch self {
        case .veryLow:  return .veryLow
        case .low:      return .low
        case .normal:   return .normal
        case .high:     return .high
        case .veryHigh: return .veryHigh
        }
    }
    
    internal var urlTaskPriority: Float {
        switch self {
        case .veryLow:  return 0.1
        case .low:      return 0.3
        case .normal:   return 0.5
        case .high:     return 0.7
        case .veryHigh: return 1.0
        }
    }
    
}
