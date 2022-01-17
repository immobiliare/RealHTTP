//
//  RealHTTP
//
//  Created by the Mobile Team @ ImmobiliareLabs
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Copyright ©2021 Immobiliare.it SpA. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

internal protocol HTTPDataLoader {
    
    var client: HTTPClient? { get set }
    var session: URLSession! { get }
    var cachePolicy: URLRequest.CachePolicy { get set }

        
    func fetch(_ request: HTTPRequest) async throws -> HTTPResponse

}
