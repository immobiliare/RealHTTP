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
    
    /// The object used to transform the request in a valid `URLRequest`.
    /// You can override it in case you need to make some special transforms.
    open var requestBuilder: HTTPRequestBuilderProtocol = HTTPRequestBuilder()
    
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
    
    /// Encoding of the parameters. By default is auto.
    open var paramsEncoding: HTTPParametersEncoding {
        get { requestBuilder.paramsEncoding }
        set { requestBuilder.paramsEncoding = newValue }
    }
    
    // MARK: - Initialization
    
    required public init(method: HTTPMethod, route: String) {
        self.method = method
        self.route = route
    }
    
    func run(in client: HTTPClient) -> AnyPublisher<Object, Err> {
        let urlRequest = try? requestBuilder.urlRequest(for: self, in: client)
        
        fatalError()
    }
    
}
