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

public protocol HTTPClientProtocol {
    
    /// Base URL.
    var baseURL: String { get set }
    
    /// Service's URLSession instance to use.
    var session: URLSession! { get set }
    
    /// Headers which are part of each request made using the client.
    var headers: HTTPHeaders { get set }
    
    /// Timeout interval for requests. Defaults to `60` seconds.
    /// Requests may override this behaviour.
    var timeout: TimeInterval { get set }
    
    /// Validators for response. Values are executed in order.
    var validators: [HTTPResponseValidator] { get set }
    
    /// The cache policy for the request. Defaults to `.useProtocolCachePolicy`.
    /// Requests may override this behaviour.
    var cachePolicy: URLRequest.CachePolicy { get set }
    
    // MARK: - Public Functions
    
    func validate(response: HTTPRawResponse) -> HTTPResponseValidatorAction

}

public extension HTTPClientProtocol {
    
    /// Validate the response with the list of validators.
    ///
    /// - Parameters:
    ///   - clientValidators: validators list.
    ///   - response: response received from server.
    /// - Returns: HTTPResponseValidatorAction
    func validate(response: HTTPRawResponse) -> HTTPResponseValidatorAction {
        for validator in validators {
            let result = validator.validate(response: response)
            guard case .passed = result else {
                return result
            }
        }
        
        return .passed
    }
    
}
