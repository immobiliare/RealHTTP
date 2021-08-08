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
#endif

public extension HTTPRequest {
    
    func publisher(in client: HTTPClient) -> AnyPublisher<Object, Error> {
        return Future { [weak self] fulfill in
            self?.run(in: client).response({ result in
                fulfill(result)
            })
        }.eraseToAnyPublisher()
    }
    
}
