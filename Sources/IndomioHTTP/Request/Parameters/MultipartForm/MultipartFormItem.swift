//
//  File.swift
//  
//
//  Created by Daniele on 29/07/21.
//

import Foundation

internal class MultipartFormItem {
    
    // MARK: - Public Properties
    
    /// Metadata assigned to the single form element.
    let headers: HTTPHeaders
    
    /// Stream of the body for this form item.
    let stream: InputStream
    
    /// Length of the body.
    let length: UInt64
    
    // MARK: - Initialization
    
    init(stream: InputStream, length: UInt64, headers: HTTPHeaders) {
        self.headers = headers
        self.stream = stream
        self.length = length
    }
    
}
