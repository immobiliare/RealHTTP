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

public class HTTPStubResponse {
    
    /// The HTTP status code to return with the response.
    public var statusCode: HTTPStatusCode = .none
    
    /// Content type of the response.
    public var contentType: HTTPContentType? = nil
    
    /// Once set this value is returned instead of the data set.
    public var failError: Error? = nil
    
    /// Contains a map of the data to return.
    public var body: HTTPStubDataConvertible? = nil
    
    /// The headers to send back with the response.
    public var headers =  HTTPHeaders()
    
    /// Allow response caching. Usually you dont want to have a cached response
    /// so the default behaviour is set to `notAllowed`.
    public var cachePolicy: URLCache.StoragePolicy = .notAllowed
    
    /// You can define a delay to return the reponse.
    /// If `nil` no delay is applied.
    public var responseDelay: TimeInterval? = nil
    
}
