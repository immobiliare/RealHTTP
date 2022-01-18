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
            body.headers[.contentType] = "\(MIMEType.application.wwwForm.rawValue); charset=utf-8"
            body.headers[.contentLength] = String(data.count)
        }
        
        return body
    }
    
}
