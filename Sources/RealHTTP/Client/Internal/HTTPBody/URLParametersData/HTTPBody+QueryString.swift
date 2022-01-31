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
    
    /// Create a new body which contains the query string with passed parameters.
    ///
    /// - Parameter parameters: parameters.
    /// - Returns: HTTPBody
    public static func urlParameters(_ parameters: HTTPRequestParametersDict) -> HTTPBody {
        let content = URLParametersData(parameters)
        var body = HTTPBody(content: content, headers: .init())
        
        if let data = try? content.encodedData() {
            body.headers[.contentType] = MIMEType.wwwFormUtf8.rawValue
            body.headers[.contentLength] = String(data.count)
        }
        
        return body
    }
    
}
