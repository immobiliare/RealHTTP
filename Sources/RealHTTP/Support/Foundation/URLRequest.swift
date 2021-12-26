//
//  File.swift
//  
//
//  Created by Daniele Margutti on 26/12/21.
//

import Foundation

internal extension URLRequest {
    
    mutating func setHTTPBody(_ body: HTTPBody) throws {
        if let stream = body.content as? HTTPStreamContent {
            httpBodyStream = stream.inputStream(recreate: false)
        } else {
            httpBody = try body.content.encodedData()
        }
    }
    
}
