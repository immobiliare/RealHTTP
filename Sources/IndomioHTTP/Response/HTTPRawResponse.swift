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
    public static func decode(_ response: HTTPRawResponse) -> Result<HTTPRawResponse, Error> {
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

/// Define what kind of data you have received.
/// - `data`: data available in memory (used when `expectedDataType` is set to `default`.
/// - `file`: used when data is written on disk (used when `expectedDataType` is set to `large`).
public enum HTTPRawData {
    case data(Data?)
    case file(URL)
    
    /// Raw data. If it's contained in a file it will
    /// be loaded and returned.
    public var data: Data? {
        switch self {
        case .data(let data):
            return data
        case .file(let fileURL):
            return Data.fromURL(fileURL)
        }
    }
    
}
