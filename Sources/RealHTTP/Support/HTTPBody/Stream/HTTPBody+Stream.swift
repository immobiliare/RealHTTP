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
//  Copyright ©2021 Immobiliare.it SpA.
//  Licensed under MIT License.
//

import Foundation

extension HTTPBody {
    
    /// Initialize a new body with stream source.
    ///
    /// - Parameter values: stream.
    /// - Returns: HTTPBody
    public static func stream(_ source: HTTPStreamContent.Source) -> HTTPBody {
        let stream = HTTPStreamContent(source: source)
        return HTTPBody(content: stream, headers: .init([
            .connection: "Keep-Alive",
            .contentLength: String(stream.length),
        ]))
    }
    
}
