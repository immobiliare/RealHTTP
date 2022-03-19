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

public typealias HTTPRequestParametersDict = [String: Any]

extension HTTPBody {
    
    /// Deprecated, see `formURLEncodedBody`.
    ///
    /// - Parameter parameters: parameters to set.
    /// - Returns: HTTPBody
    @available(*, deprecated, message: "Use formURLEncodedBody instead")
    public static func urlParameters(_ parameters: HTTPRequestParametersDict) -> HTTPBody {
        formURLEncodedBody(parameters)
    }
    
    /// Create a new body which contains the query string with passed parameters.
    ///
    /// - Parameter parameters: parameters.
    /// - Returns: HTTPBody
    public static func formURLEncodedBody(_ parameters: HTTPRequestParametersDict) -> HTTPBody {
        let content = WWWFormURLEncodedBody(parameters)
        let body = HTTPBody(content: content, headers: [
            .contentType(MIMEType.wwwFormUtf8.rawValue)
        ])
        return body
    }
    
}

extension HTTPBody {
    
    /// Return body as `WWWFormURLEncodedBody`.
    public var asFormURLEncoded: WWWFormURLEncodedBody? {
        content as? WWWFormURLEncodedBody
    }
    
}

// MARK: - WWWFormURLEncoded

extension HTTPBody {
    
    /// Encode the parameters inside the body with standard url encoding.
    public struct WWWFormURLEncodedBody: HTTPSerializableBody {
        
        // MARK: - Public Properties
        
        /// Parameters to set with url encoded body.
        public let data: URLParametersData
        
        // MARK: - Initialziation
        
        /// Initialize a new body with parameters dictionary.
        ///
        /// - Parameter parameters: parameters.
        public init(_ parameters: HTTPRequestParametersDict) {
            self.data = URLParametersData(parameters)
        }
        
        /// Add parameter to the form url encoded.
        /// If the value is `nil` no action is taken.
        ///
        /// - Parameters:
        ///   - value: value to add.
        ///   - key: key to use.
        public func set(value: Any?, forKey key: String) {
            guard let value = value else {
                return
            }

            data.parameters?[key] = value
        }
        
        /// Remove value for a given key and return the removed value, if any.
        ///
        /// - Parameter key: key.
        /// - Returns: `T?`
        @discardableResult
        public func removeValueForKey<T>(_ key: String) -> T? {
            data.parameters?.removeValue(forKey: key) as? T
        }
        
        /// Remove value for a given key and return the removed value, if any.
        ///
        /// - Parameter key: key.
        /// - Returns: `Any`
        @discardableResult
        public func removeValueForKey(_ key: String) -> Any? {
            data.parameters?.removeValue(forKey: key)
        }
        
        // MARK: - HTTPSerializableBody Conformance
        
        public func serializeData() async throws -> (data: Data, additionalHeaders: HTTPHeaders?) {
            try await data.serializeData()
        }
        
    }
    
}
