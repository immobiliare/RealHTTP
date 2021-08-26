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

// MARK: - Typealias for URLSession Response

/// This is just a typealias for raw reponse coming from underlying URLSession instance.
public typealias URLSessionResponse = (urlResponse: URLResponse?, data: HTTPRawData?, error: Error?)

// MARK: - HTTPRequest<HTTPRawResponse> ~> HTTPRawRequest

// Sometimes you don't need to get a decoded object and you just need of the raw
// response. Conforming `HTTPRawResponse` to the `HTTPDecodableResponse` allows you
// to create an `HTTPRequest<HTTPRawResponse>` where the decoded type is the raw response
// itself.
// In order to simplify the naming instead of creating `HTTPRequest<HTTPRawResponse>` you
// can use the typealias `HTTPRawRequest`.
extension HTTPRawResponse: HTTPDecodableResponse {
    public static func decode(_ response: HTTPRawResponse) -> Result<HTTPRawResponse, HTTPError> {
        .success(response)
    }
}

// MARK: - HTTPRawResponse

/// Encapsulate the result of the execution of an `HTTPRequestProtocol` conform object.
public final class HTTPRawResponse {
    
    // MARK: - Public Properties
    
    /// Executed request operation (weak referenced).
    public internal(set) weak var request: HTTPRequestProtocol?

    /// `URLResponse` object received from server.
    public let urlResponse: URLResponse?
    
    /// Casted `HTTPURLResponse` object received from server.
    public var httpResponse: HTTPURLResponse? {
        urlResponse as? HTTPURLResponse
    }
    
    /// Data received.
    public let content: HTTPRawData?
    
    /// Metrics collected for request.
    public internal(set) var metrics: HTTPRequestMetrics?

    /// Error parsed.
    public internal(set) var error: HTTPError?
    
    /// Return `true` if call ended with error.
    public var isError: Bool {
        error != nil
    }
    
    /// cURL description of the original request who generate this response.
    public internal(set) var cURLDescription: String?

    /// Keep the `URLRequest` instance of the original
    public private(set) var urlRequest: (original: URLRequest?, current: URLRequest?)
    
    /// If task is cancelled by requiring data it will saved here.
    @Published
    public internal(set) var resumableData: Data? = nil
    
    // MARK: - Initialization
    
    /// Initialize a new HTTPResponse object.
    ///
    /// - Parameters:
    ///   - request: request.
    ///   - urlRequest: url request.
    ///   - client: client source.
    ///   - response: response received from server.
    internal init(request: HTTPRequestProtocol, response: URLSessionResponse) {
        self.request = request
        self.urlResponse = response.urlResponse
        self.content = response.data
        self.error = HTTPError.fromURLResponse(response)
    }
    
    internal init(error type: HTTPError.ErrorType, error: Error? = nil, forRequest request: HTTPRequestProtocol) {
        self.request = request
        self.error = HTTPError(type, error: error)
        self.urlResponse = nil
        self.content = nil
    }
    
    internal func attachURLRequests(original: URLRequest?, current: URLRequest?) {
        self.urlRequest = (original, current)
    }
    
}

// MARK: - HTTPRawData

/// Represent the raw data received from server, which can be downloaded into a file
/// when it's a large data set or in memory for small needs.
public struct HTTPRawData {
    
    /// For a `largeData` option this value is filled with the source file where
    /// the data has been downloaded.
    public let fileURL: URL?
    
    /// Return the data downloaded.
    /// For `largeData` sets it reads the data from file every time and return it
    /// (no cache is made in order to prevent old data in memory).
    /// For normal requests you should get the temporary data downloaded from server.
    public var data: Data? {
        if let fileURL = fileURL {
            return Data.fromURL(fileURL)
        }
        
        return innerData
    }
    
    /// When data ia not written to a file this value contains the data downloaded
    /// from server and stored in memory.
    internal var innerData: Data?
    
    // MARK: - Initialization
    
    /// Initialize with large data set contained in a file.
    ///
    /// - Parameter fileURL: local url of the file with data.
    internal init(fileURL: URL) {
        self.fileURL = fileURL
        self.innerData = nil
    }
    
    /// Initialize with a data set.
    ///
    /// - Parameter data: data to set, by default it's a valid empty data
    internal init(data: Data = Data()) {
        self.fileURL = nil
        self.innerData = data
    }
    
}
