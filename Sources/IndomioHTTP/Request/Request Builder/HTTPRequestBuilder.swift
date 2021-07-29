//
//  IndomioNetwork
//
//  Created by the Mobile Team @ ImmobiliareLabs
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Copyright ©2021 Immobiliare.it SpA. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

// MARK: - HTTPRequestBuilder

/// This is the default implementation used by the library in order to produce a valid `URLRequest`
/// to execute in a client instance.
open class HTTPRequestBuilder: HTTPRequestBuilderProtocol {
    
    // MARK: - Public Properties
    
    /// Defines how the parameters are encoded into the request.
    public var paramsEncoding: HTTPParametersEncoding
    
    // MARK: - Additional Configuration
    
    /// Specify how array parameter's value are encoded into the request.
    /// By default the `withBrackets` option is used and array are encoded as `key[]=value`.
    public var arrayEncoding: ArrayEncodingStyle = .withBrackets
    
    /// Specify how boolean values are encoded into the request.
    /// The default behaviour is `asNumbers` where `true=1`, `false=0`.
    public var boolEncoding: BoolEncodingStyle = .asNumbers
    
    // MARK: - Initialization
    
    public init(_ paramsEncoding: HTTPParametersEncoding = .auto) {
        self.paramsEncoding = paramsEncoding
    }
    
    // MARK: - Public Methods
    
    open func urlRequest(for request: HTTPRequestProtocol, in client: HTTPClient) throws -> URLRequest {
        // Create the full URL of the request.
        let fullURLString = (client.baseURL + request.route)
        guard let fullURL = URL(string: fullURLString) else {
            throw IndomioHTTPError.invalidURL(fullURLString) // failed to produce a valid url
        }
        
        // Setup the new URLRequest instance
        let cachePolicy = request.cachePolicy ?? client.cachePolicy
        let timeout = request.timeout ?? client.timeout
        let headers = (client.headers + request.headers)
        
        var urlRequest = try URLRequest(url: fullURL,
                                        method: request.method,
                                        cachePolicy: cachePolicy,
                                        timeout: timeout,
                                        headers: headers)
        // Apply modifier if set
        try request.urlRequestModifier?(&urlRequest)

        // Apply parameters if set
        guard let parameters = request.parameters, parameters.isEmpty == false else {
            return urlRequest // no parameters set
        }
        
        guard paramsEncoding.encodesParametersInURL(request.method) else {
            if urlRequest.headers[.contentType] == nil {
                urlRequest.headers[.contentType] = "application/x-www-form-urlencoded; charset=utf-8"
            }
            
            urlRequest.httpBody = nil
            return urlRequest
        }
        
        // Encode parameters
        if var urlComponents = URLComponents(url: fullURL, resolvingAgainstBaseURL: false) {
            let percentEncodedQuery = (urlComponents.percentEncodedQuery.map {
                $0 + "&"
            } ?? "") + encodeParameters(parameters)
            urlComponents.percentEncodedQuery = percentEncodedQuery
            urlRequest.url = urlComponents.url
        }
        
        return urlRequest
    }
    
    // MARK: - Private Functions
    
    /// Encode parameters passed and produce a final string.
    ///
    /// - Parameter parameters: parameters.
    /// - Returns: String encoded
    private func encodeParameters(_ parameters: [String: Any]) -> String {
        var components = [(String, String)]()

        for key in parameters.keys.sorted(by: <) {
            let value = parameters[key]!
            components += encodeKey(key, withValue: value)
        }
        
        return components.map {
            "\($0)=\($1)"
        }.joinedWithAmpersands()
    }
    
    /// Encode a single object according to settings.
    ///
    /// - Parameters:
    ///   - key: key of the object to encode.
    ///   - value: value to encode.
    /// - Returns: list of encoded components
    private func encodeKey(_ key: String, withValue value: Any) -> [(String, String)] {
        var allComponents: [(String, String)] = []
        
        switch value {
        // Encode a Dictionary
        case let dictionary as [String: Any]:
            for (innerKey, value) in dictionary {
                allComponents += encodeKey("\(key)[\(innerKey)]", withValue: value)
            }
            
        // Encode an Array
        case let array as [Any]:
            array.forEach {
                allComponents += encodeKey(arrayEncoding.encode(key), withValue: $0)
            }
            
        // Encode a Number
        case let number as NSNumber:
            if number.isBool {
                allComponents += [(key.queryEscaped, boolEncoding.encode(number.boolValue).queryEscaped)]
            } else {
                allComponents += [(key.queryEscaped, "\(number)".queryEscaped)]
            }
            
        // Encode a Boolean
        case let bool as Bool:
            allComponents += [(key.queryEscaped, boolEncoding.encode(bool).queryEscaped)]
            
        default:
            allComponents += [(key.queryEscaped, "\(value)".queryEscaped)]
            
        }
        
        return allComponents
    }
}

// MARK: - HTTPRequestBuilder (ArrayEncoding, BoolEncoding)

public extension HTTPRequestBuilder {
    
    /// Configure how arrays objects must be encoded in a request.
    ///
    /// - `withBrackets`: An empty set of square brackets is appended to the key for every value.
    /// - `noBrackets`: No brackets are appended. The key is encoded as is.
    enum ArrayEncodingStyle {
        case withBrackets
        case noBrackets
        
        internal func encode(_ key: String) -> String {
            switch self {
            case .withBrackets: return "\(key)[]"
            case .noBrackets:   return key
            }
        }
    }
    
    /// Configures how `Bool` parameters are encoded in a requext.
    ///
    /// - `asNumbers`:  Encode `true` as `1`, `false` as `0`.
    /// - `asLiterals`: Encode `true`, `false` as string literals.
    enum BoolEncodingStyle {
        case asNumbers
        case asLiterals
        
        internal func encode(_ value: Bool) -> String {
            switch self {
            case .asNumbers:    return value ? "1" : "0"
            case .asLiterals:   return value ? "true" : "false"
            }
        }
        
    }
    
}
