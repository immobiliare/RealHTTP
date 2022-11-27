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

extension HTTPBody {
 
    /// Return the body as `StreamContent`.
    public var asStream: StreamContent? {
        content as? StreamContent
    }
    
}
