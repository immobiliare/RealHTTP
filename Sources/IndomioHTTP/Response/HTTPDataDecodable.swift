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

public protocol HTTPDataDecodable {
    
    static func decode(_ response: HTTPRawResponse) throws -> Self
    
}

// Provide default implementation for Decodable models.
public extension HTTPDataDecodable where Self: Decodable {

    static func decode(_ response: HTTPRawResponse) throws -> Self {
        guard let data = response.data else {
            fatalError()
        }
        
        let decoder = JSONDecoder()
        let model = try decoder.decode(Self.self, from: data)
        return model
    }
    
}
