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

// MARK: - HTTPResponse

public struct HTTPResponse {

    // MARK: - Public Properties
    
    public internal(set) var metrics: URLSessionTaskMetrics?
    
    /// `URLResponse` object received from server.
    public var urlResponse: URLResponse?
    
    /// Data received.
    public var data: Data?
    
    /// Error parsed.
    public var error: HTTPError?
    
    public weak var request: HTTPRequest?
    
    internal init(errorType: HTTPError.ErrorType = .internal, error: Error?) {
        self.error = HTTPError(errorType, error: error)
    }

    internal init(response: DataLoaderResponse) {
        self.data = response.data
        self.metrics = response.metrics
        self.request = response.request
        self.urlResponse = response.urlResponse
        self.error = HTTPError.fromResponse(response)
    }
    
}
