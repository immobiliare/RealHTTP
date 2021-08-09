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

#if canImport(Combine)
import Combine

public extension HTTPRequest {
    
    /*
     // NOTE: Evaluating alternative with Future for single results.
     
     func run(in client: HTTPClient) -> AnyPublisher<Object, Error> {
        return Future { [weak self] fulfill in
            self?.run(in: client).response({ result in
                fulfill(result)
            })
        }.eraseToAnyPublisher()
    }
     */
    
    /// Create a new publisher which execute and return the result of the call.
    ///
    /// - Parameters:
    ///   - client: client in which the request will be executed.
    ///   - queue: queue where the result is called, by default is `main`.
    /// - Returns: HTTPObjectPublisher
    func objectPublisher(client: HTTPClientProtocol, queue: DispatchQueue = .main) -> Combine.Publishers.HTTPObjectPublisher<Object> {
        Combine.Publishers.HTTPObjectPublisher(self, client: client, queue: queue)
    }
    
    /// Create a new publisher which execute and return the raw response of the call.
    ///
    /// - Parameters:
    ///   - client: client in which the request will be executed.
    ///   - queue: queue where the result is called, by default is `main`.
    /// - Returns: HTTPRawResponsePublisher
    func rawResponsePublisher(client: HTTPClientProtocol, queue: DispatchQueue = .main) -> Combine.Publishers.HTTPRawResponsePublisher {
        Combine.Publishers.HTTPRawResponsePublisher(self, client: client, queue: queue)
    }
    
}
#endif
