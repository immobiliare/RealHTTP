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
import Combine

open class HTTPRequest<Object: HTTPDataDecodable, Err: Error>: HTTPRequestProtocol {
    
    // MARK: - Public Properties
    
    /// Route to the endpoint.
    open var route: String

    /// Number of retries for this request. By default is set to `0` which means
    /// no retries are executed.
    open var maxRetries: Int = 0
    
    /// Timeout interval.
    open var timeout: TimeInterval?
    
    /// HTTP Method for request.
    open var method: HTTPMethod
    
    /// Headers to send along the request.
    open var headers = HTTPHeaders()
    
    /// Parameters for request.
    open var parameters: HTTPRequestParameters?
    
    /// Cache policy.
    open var cachePolicy: URLRequest.CachePolicy?
    
    /// Request modifier callback.
    open var urlRequestModifier: HTTPURLRequestModifierCallback?
    
    // MARK: - Initialization
    
    required public init(method: HTTPMethod, route: String) {
        self.method = method
        self.route = route
    }
    
    func run(in client: HTTPClient) -> AnyPublisher<Object, Err> {
        let urlRequest = try? urlRequest(for: self, in: client)
        print(urlRequest)
        fatalError()
    }
    
    // MARK: - Private Functions
    
    open func urlRequest(for request: HTTPRequestProtocol, in client: HTTPClient) throws -> URLRequest {
        // Create the full URL of the request.
        let fullURLString = (client.baseURL + request.route)
        guard let fullURL = URL(string: fullURLString) else {
            throw IndomioHTTPError.invalidURL(fullURLString) // failed to produce a valid url
        }
        
        // Setup the new URLRequest instance
        let cachePolicy = request.cachePolicy ?? client.cachePolicy
        let timeout = request.timeout ?? client.timeout
        let headers = (client.headers + request.headers)
        
        var urlRequest = try URLRequest(url: fullURL,
                                        method: request.method,
                                        cachePolicy: cachePolicy,
                                        timeout: timeout,
                                        headers: headers)
        
        // Encode parameters/body
        try parameters?.encodeParametersIn(request: &urlRequest)
        
        // Apply modifier if set
        try request.urlRequestModifier?(&urlRequest)

        return urlRequest
    }
    
}
