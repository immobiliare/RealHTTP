//
//  RealHTTP
//  Lightweight Async/Await Network Layer/Stubber for Swift
//
//  Created & Maintained by Mobile Platforms Team @ ImmobiliareLabs.it
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Authors:
//   - Daniele Margutti <hello@danielemargutti.com>
//
//  Copyright ©2022 Immobiliare.it SpA.
//  Licensed under MIT License.
//

import Foundation
#if canImport(Combine)
import Combine

public extension HTTPRequest {
    
    /// Return a `Future` instance to catch the result of the operation.
    ///
    /// - Parameters:
    ///   - client: client in which the request will be executed, if not specified `shared` is used.
    /// - Returns: AnyPublisher<Object, Error>
    func fetchPublisher(in client: HTTPClient = .shared) -> AnyPublisher<HTTPResponse, Error> {
        return Future { fulfill in
            Task {
                do {
                    let response = try await self.fetch(client)
                    fulfill(.success(response))
                } catch {
                    fulfill(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
}
#endif
