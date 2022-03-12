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

extension HTTPBody {
    
    /// Initialize a new body with stream source.
    ///
    /// - Parameters:
    ///   - source: stream source.
    ///   - contentType: content type to set.
    /// - Returns: `HTTPBody`
    public static func stream(_ source: StreamContent.Source, contentType: MIMEType) -> HTTPBody {
        let stream = StreamContent(source: source)
        return HTTPBody(content: stream, headers: .init([
            .connection: "Keep-Alive",
            .contentType: contentType.rawValue
        ]))
    }
    
}
