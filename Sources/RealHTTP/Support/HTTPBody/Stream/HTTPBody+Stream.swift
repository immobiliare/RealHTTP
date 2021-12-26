//
//  File.swift
//  
//
//  Created by Daniele Margutti on 26/12/21.
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
