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

extension HTTPClientDelegate {
    
    // Some methods are set here due to their optional nature.
    
    func client(_ client: HTTPClientProtocol, didEnqueue request: ExecutedRequest) {}
    func client(_ client: HTTPClientProtocol, didReceiveAuthChallangeFor request: ExecutedRequest,
                authChallenge: URLAuthenticationChallenge) {}
    func client(_ client: HTTPClientProtocol, didCollectedMetricsFor request: ExecutedRequest,
                metrics: HTTPRequestMetrics) {}
}
