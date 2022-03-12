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

// MARK: - WWWFormURLEncoded

extension HTTPBody {
    
    /// Encode the parameters inside the body with standard url encoding.
    public struct WWWFormURLEncodedBody: HTTPSerializableBody {
        
        // MARK: - Public Properties
        
        /// Parameters to set with url encoded body.
        public let parameters: URLParametersData
        
        // MARK: - Initialziation
        
        /// Initialize a new body with parameters dictionary.
        ///
        /// - Parameter parameters: parameters.
        public init(_ parameters: HTTPRequestParametersDict) {
            self.parameters = URLParametersData(parameters)
        }
        
        // MARK: - HTTPSerializableBody Conformance
        
        public func serializeData() async throws -> (data: Data, additionalHeaders: HTTPHeaders?) {
            try await parameters.serializeData()
        }
        
    }
    
}
