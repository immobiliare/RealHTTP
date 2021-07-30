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

public class URLParametersData: HTTPRequestEncodableData {
    
    // MARK: - Public Properties
    
    /// Parameters to encode.
    public var parameters: HTTPRequestParametersDict?
    
    /// Where parameters must be encoded.
    public var destination: Destination
    
    // MARK: - Additional Configuration
    
    /// Specify how array parameter's value are encoded into the request.
    /// By default the `withBrackets` option is used and array are encoded as `key[]=value`.
    public var arrayEncoding: ArrayEncodingStyle = .withBrackets
    
    /// Specify how boolean values are encoded into the request.
    /// The default behaviour is `asNumbers` where `true=1`, `false=0`.
    public var boolEncoding: BoolEncodingStyle = .asNumbers
    
    // MARK: - Initialization
    
    /// Initialize a new `URLParametersData` encoder with given destination.
    ///
    /// - Parameters:
    ///   - destination: destination of the url produced.
    ///   - parameters: parameters to encode.
    internal init(in destination: Destination, parameters: HTTPRequestParametersDict?) {
        self.destination = destination
        self.parameters = parameters
    }
    
    /// Initialize to produce query parameters.
    ///
    /// - Parameter queryParameters: query parameters.
    public convenience init(queryParameters: HTTPRequestParametersDict) {
        self.init(in: .queryString, parameters: queryParameters)
    }
    
    // MARK: - Encoding
    
    public func encodeParametersIn(request: inout URLRequest) throws {
        // Apply parameters if set
        guard let parameters = self.parameters, parameters.isEmpty == false else {
            return // no parameters set
        }
        
        guard destination == .queryString else {
            if request.headers[.contentType] == nil {
                request.headers[.contentType] = "application/x-www-form-urlencoded; charset=utf-8"
            }
            
            request.httpBody = nil
            return
        }
        
        // Encode parameters
        if let fullURL = request.url,
           var urlComponents = URLComponents(url: fullURL, resolvingAgainstBaseURL: false) {
            let percentEncodedQuery = (urlComponents.percentEncodedQuery.map {
                $0 + "&"
            } ?? "") + encodeParameters(parameters)
            urlComponents.percentEncodedQuery = percentEncodedQuery
            request.url = urlComponents.url
        }
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

public extension URLParametersData {
    
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

// MARK: - HTTPParametersDestination

extension URLParametersData {
        
    /// Defines how the url encoded query string must be applied to the request.
    ///
    /// - `queryString` sets/appends encoded query string result to existing query string.
    /// - `httpBody`: sets encoded query string result as the HTTP body.
    public enum Destination {
        case queryString
        case httpBody
    }
    
}
