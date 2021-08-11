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

public enum HTTPMatcherLocation {
    case body
    case headersValue
    case headersKey
    case url
}

public protocol HTTPStubMatcherProtocol {
    
    func matches(request: URLRequest, forStub stub: HTTPStubRequest) -> Bool
    
}
