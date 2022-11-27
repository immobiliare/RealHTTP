//
//  RealHTTP
//  Lightweight Async/Await Network Layer/Stubber for Swift
//
//  Created & Maintained by Mobile Platforms Team @ ImmobiliareLabs.it
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Created by: Daniele Margutti <hello@danielemargutti.com>

//  CONTRIBUTORS:
//  Thank you to all the contributors who made this project better:
//  <https://github.com/immobiliare/RealHTTP/graphs/contributors>
//
//  Copyright ©2022 Immobiliare.it SpA.
//  Licensed under MIT License.
//

import Foundation

/// `HTTPEchoResponse` respond with the same body, cookies and headers of the request.
public class HTTPEchoResponse: HTTPStubResponse {
    
    public override func adaptForRequest(_ request: URLRequest) -> HTTPStubResponse {
        let response = HTTPStubResponse()
        response.body = request.body
        response.statusCode = .ok
        response.headers = HTTPHeaders(rawDictionary: request.allHTTPHeaderFields)
        return response
    }
    
}
