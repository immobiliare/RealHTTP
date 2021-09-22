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
#if canImport(Combine)
import Combine

public extension HTTPRequest {
    
    /// Return a `Future` instance to catch the result of the operation.
    ///
    /// - Parameters:
    ///   - client: client in which the request will be executed.
    ///   - queue: queue where the result is called, by default is `main`.
    /// - Returns: AnyPublisher<Object, Error>
     func future(in client: HTTPClient, queue: DispatchQueue = .main) -> AnyPublisher<Object, HTTPError> {
        return Future { [weak self] fulfill in
            self?.run(in: client).onResult { result in
                fulfill(result)
            }
        }.eraseToAnyPublisher()
    }
    
    /// Create a new publisher which execute and return the result of the call.
    ///
    /// - Parameters:
    ///   - client: client in which the request will be executed.
    ///   - queue: queue where the result is called, by default is `main`.
    /// - Returns: HTTPObjectPublisher
    func resultPublisher(in client: HTTPClientProtocol) -> Combine.Publishers.HTTPResultPublisher<Object> {
        Combine.Publishers.HTTPResultPublisher(self, client: client)
    }
    
    /// Create a new publisher which execute and return the raw response of the call.
    ///
    /// - Parameters:
    ///   - client: client in which the request will be executed.
    ///   - queue: queue where the result is called, by default is `main`.
    /// - Returns: HTTPRawResponsePublisher
    func responsePublisher(in client: HTTPClientProtocol) -> Combine.Publishers.HTTPRawResponsePublisher {
        Combine.Publishers.HTTPRawResponsePublisher(self, client: client)
    }
    
}
#endif
