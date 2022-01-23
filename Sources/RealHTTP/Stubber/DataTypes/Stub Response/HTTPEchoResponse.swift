//
//  File.swift
//  
//
//  Created by Daniele Margutti on 23/01/22.
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
