//
//  RealHTTP
//  Lightweight Async/Await Network Layer/Stubber for Swift
//
//  Created & Maintained by Mobile Platforms Team @ ImmobiliareLabs.it
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Created by: Daniele Margutti <hello@danielemargutti.com>

//  CONTRIBUTORS:
//  Thank you to all the contributors who made this project better:
//  <https://github.com/immobiliare/RealHTTP/graphs/contributors>
//
//  Copyright ©2022 Immobiliare.it SpA.
//  Licensed under MIT License.
//

import Foundation

// MARK: - HTTPBody

/// Defines the body of a request, including the content's body and additional headers.
public struct HTTPBody {
    
    // MARK: - Public Static Properties
    
    /// No data to send.
    public static let empty = HTTPBody(content: Data())

    // MARK: - Public Properties
    
    /// Content of the body.
    public var content: HTTPSerializableBody
    
    // MARK: - Internal Properties
    
    /// Additional headers set by the particular body configuration.
    ///
    /// These values may override both client's headers and specific body's headers.
    /// Final headers are sum of the following properties in order:  
    ///     - client's common headers
    ///     - request's body specific headers
    ///     - request's user defined headers
    internal var headers: HTTPHeaders
    
    // MARK: - Initialization
    
    /// Initialize a new body.
    ///
    /// - Parameters:
    ///   - content: content of the body.
    ///   - headers: additional headers to set.
    internal init(content: HTTPSerializableBody, headers: HTTPHeaders = .init()) {
        self.content = content
        self.headers = headers
    }
    
}

// MARK: - HTTPBody for Raw Data

extension HTTPBody {
        
    /// Initialize a new body with raw data.
    ///
    /// - Parameters:
    ///   - content: content data.
    ///   - mimeType: mime type to assign.
    /// - Returns: HTTPBody
    public static func data(_ content: Data, contentType mimeType: MIMEType) -> HTTPBody {
        HTTPBody(content: content, headers: .init([.contentType: mimeType.rawValue]))
    }
    
    /// Initialize a new body with raw string which will be encoded in .utf8.
    ///
    /// - Parameters:
    ///   - content: content string.
    ///   - contentType: content type to assign, by default is set to `.text.plain`
    /// - Returns: HTTPBody
    public static func string(_ content: String, contentType: MIMEType = .textPlain) -> HTTPBody {
        .data(content.data(using: .utf8) ?? Data(), contentType: contentType)
    }
    
}

extension HTTPBody {
    
    /// Return content as Data.
    public var asData: Data? {
        content as? Data
    }
    
    /// Return content as String.
    public var asString: String? {
        content as? String
    }
    
}
