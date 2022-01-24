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
    /// If the file is saved on disk (`dataFileURL != nil`) calling this method
    /// will cause the system to read file and get it as output.
    public var data: Data? {
        if let dataFileURL = dataFileURL {
            return try? Data(contentsOf: dataFileURL)
        } else {
            return innerData
        }
    }
    
    /// If it's a large data transfer (`transferMode = .largeData`) the output
    /// of the call is automatically saved on disk at this link.
    /// The file is your responsibility, you should delete if once you've done.
    public let dataFileURL: URL?
    
    /// Error parsed.
    public let error: HTTPError?
    
    /// Return `true` if call ended with error.
    public var isError: Bool {
        error != nil
    }
    
    /// Weak reference to the original request.
    public internal(set) weak var request: HTTPRequest?
    
    /// HTTP status code of the response, if available.
    public let statusCode: HTTPStatusCode
    
    /// Headers received into the response.
    public var headers: HTTPHeaders {
        httpResponse?.headers ?? HTTPHeaders()
    }
    
    // MARK: - Private Properties
    
    /// Data retrived from server when `transferMode != largeData`.
    private var innerData: Data?
    
    // MARK: - Initialization
    
    /// Initialize to produce an error.
    ///
    /// - Parameters:
    ///   - errorType: error type.
    ///   - error: optional error instance received.
    internal init(errorType: HTTPError.ErrorCategory = .internal, error: Error?) {
        self.error = HTTPError(errorType, error: error)
        self.innerData = nil
        self.metrics = nil
        self.urlResponse = nil
        self.dataFileURL = nil
        self.statusCode = .none
    }
    
    /// Initialize with response from data loader.
    ///
    /// - Parameter response: response received.
    internal init(response: HTTPDataLoaderResponse) {
        self.urlResponse = response.urlResponse
        self.error = HTTPError.fromResponse(response)
        self.statusCode = HTTPStatusCode.fromResponse(response.urlResponse)
        self.innerData = response.data
        self.dataFileURL = response.dataFileURL
        self.metrics = HTTPMetrics(metrics: response.metrics)
        self.request = response.request
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
    
    /// Decode raw JSON data using `JSONSerialization.jsonObject`.
    ///
    /// - Returns: T?
    public func decodeJSONData<T>(_ decodable: T.Type,
                                  options: JSONSerialization.ReadingOptions = []) throws -> T? {
        guard let data = data else { return nil }

        let object = try JSONSerialization.jsonObject(with: data, options: options)
        return object as? T
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
