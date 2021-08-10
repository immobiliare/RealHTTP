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

public struct HTTPStubRequest: Equatable {
    
    // MARK: - Public Properties
    
    /// The type of the data which is returned.
    public let responseType: MockResponseDataType
    
    /// Once set this value is returned instead of the data set.
    public let failError: Error?
    
    /// The HTTP status code to return with the response.
    public let statusCode: HTTPStatusCode
    
    /// Contains a map of the data to return for each kind of http method
    /// used to call this request.
    public let content: [HTTPMethod: MockRequestDataConvertible?]
    
    /// You can define a delay to return the reponse.
    /// If `nil` no delay is applied.
    public var responseDelay: DispatchTimeInterval?
    
    /// Allow response caching. Usually you dont want to have a cached response
    /// so the default behaviour is set to `notAllowed`.
    public var cachePolicy: URLCache.StoragePolicy = .notAllowed
    
    /// The headers to send back with the response.
    public var headers: HTTPHeaders?
    
    /// Matching options for request.
    public var matchRules = [HTTPStubMatcher]()
        
    // MARK: - Initialization
    
    /// Create a mock for a given data type to return.
    /// It will be automatically matched based on a URL created from the given parameters.
    ///
    /// - Parameters:
    ///   - response: type of data to return.
    ///   - code: http status code of the response.
    ///   - content: content of the response based upon the http method of the request.
    ///   - headers: headers to set along with the data inside the response.
    public init(response: MockResponseDataType, code: HTTPStatusCode,
                content: [HTTPMethod: MockRequestDataConvertible?],
                headers: HTTPHeaders?) {
        self.responseType = response
        self.statusCode = code
        self.content = content
        self.headers = headers
        self.failError = nil
    }
    
    public static func == (lhs: HTTPStubRequest, rhs: HTTPStubRequest) -> Bool {
        false
    }
    
}
