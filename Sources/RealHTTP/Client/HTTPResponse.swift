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
    
    // MARK: - Decoding
    
    /// Decode a raw response using `Decodable` object type.
    ///
    /// - Returns: `T` or `nil` if no response has been received.
    public func decode<T: Decodable>(_ decodable: T.Type, decoder: JSONDecoder = .init()) throws -> T? {
        guard let data = data else { return nil }
        
        let decodedObj = try decoder.decode(T.self, from: data)
        return decodedObj
    }
    
    /// Decode a raw response and transform it to passed `HTTPDecodableResponse` type.
    ///
    /// - Returns: T or `nil` if response is empty.
    public func decode<T: HTTPDecodableResponse>(_ decodable: T.Type) throws -> T? {
        try decodable.decode(self)
    }
        
}

// MARK: - Automatic Decoding of Objects

// Combination of a decodable response which can be parsed via custom parser or Codable.
public typealias DecodableResponse = HTTPDecodableResponse & Decodable

// MARK: - HTTPDecodableResponse

/// If you can't implement `Decodable` you can customize your own decoding mechanism.
public protocol HTTPDecodableResponse {
    
    /// A custom decoder function.
    ///
    /// - Returns: a valid instance of `Self` or `nil`.
    static func decode(_ response: HTTPResponse) throws -> Self?
    
}
