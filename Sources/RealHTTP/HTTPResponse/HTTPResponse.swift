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


// MARK: - Typealias for URLSession Response

/// This is just a typealias for raw reponse coming from underlying URLSession instance.
public typealias URLSessionResponse = (urlResponse: URLResponse?, data: Data?, error: Error?)

// MARK: - HTTPResponse

public struct HTTPResponse {
    
    // MARK: - Public Properties
    
    /// Reference to the request.
    public let request: HTTPRequest
    
    /// Retrived data from server.
    public var data: Data?
    
    // MARK: - Initialization
    
    /// Initialize a new response object with the result of a network call.
    ///
    /// - Parameters:
    ///   - request: request which originate the response.
    ///   - response: response received from underlying `URLSession` delegate instance.
    internal init(request: HTTPRequest, response: URLSessionResponse) {
        self.request = request
    }
    
}
