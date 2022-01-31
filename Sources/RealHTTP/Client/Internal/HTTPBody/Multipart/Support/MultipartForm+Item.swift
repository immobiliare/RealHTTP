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

extension HTTPBody.MultipartForm {
    
    /// A single item of the MultipartForm object.
    internal class Item {
        
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
        
        // MARK: - Encoding
        
        /// Encode a stream and produce the Data.
        ///
        /// - Parameter item: item to encode.
        /// - Throws: throw an exception if encoding fails.
        /// - Returns: Data
        internal func encodedData() throws -> Data {
            try stream.readData()
        }
        
    }
    
}
