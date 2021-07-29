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

extension URLRequest {
    
    /// Create a new instance of `URLRequest` with passed settings.
    ///
    /// - Parameters:
    ///   - url: url convertible value.
    ///   - method: http method to use.
    ///   - cachePolicy: cache policy to use.
    ///   - timeout: timeout interval.
    ///   - headers: headers to use.
    /// - Throws: throw an exception if url is not valid and cannot be converted to request.
    public init(url: URLConvertible, method: HTTPMethod,
                cachePolicy: URLRequest.CachePolicy,
                timeout: TimeInterval,
                headers: HTTPHeaders? = nil) throws {
        let url = try url.asURL()

        self.init(url: url)

        self.httpMethod = method.rawValue
        self.timeoutInterval = timeout
        self.allHTTPHeaderFields = headers?.asDictionary
    }
    
}
