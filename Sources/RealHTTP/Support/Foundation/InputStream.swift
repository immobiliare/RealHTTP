//
//  File.swift
//  
//
//  Created by Daniele Margutti on 26/12/21.
//

import Foundation

public extension InputStream {
    
    /// Read all the data of the input stream.
    ///
    /// - Returns: Data
    internal func readData() throws -> Data {
        open()
        
        defer {
            close()
        }
        
        var data = Data()
        
        /// The optimal read/write buffer size for input/output streams is 1024bytes (1KB).
        /// <https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/Streams/Articles/ReadingInputStreams.html>
        let bufferSize = 1024
        
        while hasBytesAvailable {
            var buffer = [UInt8](repeating: 0, count: bufferSize)
            let bytesRead = read(&buffer, maxLength: bufferSize)

            if let error = streamError {
                throw HTTPError(.multipartStreamReadFailed, error: error)
            }

            guard bytesRead > 0 else {
                break
            }

            data.append(buffer, count: bytesRead)
        }
        
        return data
    }
    
    
}
