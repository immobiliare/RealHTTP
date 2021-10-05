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

/// Identify a list of events you can monitor during the lifecycle of the client instance.
public protocol HTTPClientDelegate: AnyObject {
    typealias ExecutedRequest = (request: HTTPRequestProtocol, task: URLSessionTask)
    
    /// A new request is enqueued into the client's pool.
    ///
    /// - Parameters:
    ///   - client: client target of the request.
    ///   - request: request instance.
    func client(_ client: HTTPClientProtocol, didEnqueue request: ExecutedRequest)
    
    /// Client is about to execute the request.
    ///
    /// - Parameters:
    ///   - client: client target of the request.
    ///   - request: request instance.
    func client(_ client: HTTPClientProtocol, didExecute request: ExecutedRequest)
    
    
    /// Method is called when a http redirection is made.
    /// Return `nil` to use the `followRedirectsMode` of the parent client.
    ///
    /// - Parameters:
    ///   - client: client target of the request.
    ///   - request: request instance.
    ///   - response: response received along with the redirect request.
    ///   - newRequest: new request filled out with the new location.
    ///                 It contains the same http body/method and parameters with the new url.
    func client(_ client: HTTPClientProtocol, willPerformRedirect request: ExecutedRequest,
                response: HTTPRawResponse,
                newRequest: inout URLRequest) -> HTTPRedirectAction?
    
    /// Client receive an auth challenge which will be managed by the `security` property of the
    /// request itself or global client's one.
    ///
    /// - Parameters:
    ///   - client: client target of the request.
    ///   - request: request instance.
    ///   - authChallenge: challenge received.
    func client(_ client: HTTPClientProtocol, didReceiveAuthChallangeFor request: ExecutedRequest,
                authChallenge: URLAuthenticationChallenge)
    
    /// Client executed the request and collected relative metrics stats.
    ///
    /// - Parameters:
    ///   - client: client target of the request.
    ///   - request: request instance.
    ///   - metrics: collected metrics data.
    func client(_ client: HTTPClientProtocol, didCollectedMetricsFor request: ExecutedRequest,
                metrics: HTTPRequestMetrics)
    
    
    /// Client did complete the request.
    ///
    /// - Parameters:
    ///   - client:  client target of the request.
    ///   - request: request instance.
    ///   - response: response received (either success or error)
    func client(_ client: HTTPClientProtocol, didFinish request: ExecutedRequest,
                response: HTTPRawResponse)
    
}

public extension HTTPClientDelegate {
    
    // Some methods are set here due to their optional nature.
    func client(_ client: HTTPClientProtocol, didEnqueue request: ExecutedRequest) {
    }
    
    func client(_ client: HTTPClientProtocol, didReceiveAuthChallangeFor request: ExecutedRequest,
                authChallenge: URLAuthenticationChallenge) {
    }
    
    func client(_ client: HTTPClientProtocol, didCollectedMetricsFor request: ExecutedRequest,
                metrics: HTTPRequestMetrics) {
    }
    
    func client(_ client: HTTPClientProtocol, willPerformRedirect request: ExecutedRequest,
                response: HTTPRawResponse, newRequest: inout URLRequest) -> HTTPRedirectAction? {
        nil // uses `followRedirectsMode` of the client by default.
    }
    
}

// MARK: - HTTPRedirectAction

/// Action to follow for a redirect request.
/// - `refuse`: refuse redirection.
/// - `follow`: follow redirection to specified request by using the proposed URLSession urlrequesdt.
/// - `followCopy`: follow redirection and
public enum HTTPRedirectAction {
    case refuse
    case follow(URLRequest)
}

// MARK: - HTTPRedirectMode

/// Follow redirects mechanism mode.
/// - `follow`: follow the redirect with the default new urlrequest.
///             new request has a different url but not maintain the original method/body/headers.
/// - `followCopy`: follow the redirect with the new urlrequest proposed
///                 which has the same method/body/headers of the original one.
public enum HTTPRedirectMode {
    case follow
    case followCopy
}
