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

/// This is the raw response received from server. It includes all the
/// data collected from the request including metrics and errors.
public struct HTTPResponse {

    // MARK: - Public Properties
    
    /// Each metrics  contains the taskInterval and redirectCount, as well as metrics for each
    /// request-and-response transaction made during the execution of the task.
    public let metrics: HTTPMetrics?
    
    /// `URLResponse` object received from server.
    public let urlResponse: URLResponse?
    
    /// Casted `HTTPURLResponse` object received from server.
    public var httpResponse: HTTPURLResponse? {
        urlResponse as? HTTPURLResponse
    }
    
    /// Raw data received from server.
    public let data: Data?
    
    /// Error parsed.
    public let error: HTTPError?
    
    /// Return `true` if call ended with error.
    public var isError: Bool {
        error != nil
    }
    
    /// Weak reference to the original request.
    public internal(set) weak var request: HTTPRequest?
    
    /// HTTP status code of the response, if available.
    public var statusCode: HTTPStatusCode? {
        httpResponse?.status
    }
    
    // MARK: - Initialization
    
    /// Initialize to produce an error.
    ///
    /// - Parameters:
    ///   - errorType: error type.
    ///   - error: optional error instance received.
    internal init(errorType: HTTPError.ErrorType = .internal, error: Error?) {
        self.error = HTTPError(errorType, error: error)
        self.data = nil
        self.metrics = nil
        self.urlResponse = nil
    }
    
    /// Initialize with response from data loader.
    ///
    /// - Parameter response: response received.
    internal init(response: HTTPDataLoaderResponse) {
        self.data = response.data
        self.metrics = HTTPMetrics(metrics: response.metrics)
        self.request = response.request
        self.urlResponse = response.urlResponse
        self.error = HTTPError.fromResponse(response)
    }
        
}
