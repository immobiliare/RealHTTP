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

public struct HTTPProgress {
    
    // MARK: - Support Structures
    
    /// Kind of operation which identify the progress.
    /// - `upload`: upload operation to remote server.
    /// - `download`: download operation from a remote server.
    public enum Operation {
        case upload
        case download
    }
    
    // MARK: - Public Properties
    
    /// Kind of transfer.
    public internal(set) var operation: Operation = .download
    
    /// Progress object which contains additional informations.
    public let progress: Progress
    
    /// The number of bytes sent/received since the last time this delegate method was called.
    public let currentLength: Int64
    
    /// The expected length of the body data.
    /// Depending by the server this value can be 0 if no expected length can be determined
    /// (ie. by reading the `Content-Length` header .
    /// Local uploades includes this value automatically when made using the library.
    public let expectedLength: Int64
    
    /// The percentage of the progression. If no percentage can be determined by the data
    /// this value return `nil`.
    public let percentage: Float?
    
    // MARK: - Initialization
    
    /// Initialize a new progress structure with the data.
    ///
    /// - Parameters:
    ///   - operation: kind of operation.
    ///   - progress: progress instance.
    ///   - current: current downloaded/uploaded bytes.
    ///   - expected: expected bytes.
    internal init(operation: Operation = .download,
                  progress: Progress,
                  currentLength: Int64, expectedLength: Int64) {
        self.operation = operation
        self.progress = progress
        self.currentLength = currentLength
        self.expectedLength = expectedLength
        
        if expectedLength != NSURLSessionTransferSizeUnknown, expectedLength != 0 {
            let slice = Float(1.0)/Float(expectedLength)
            self.percentage = slice*Float(currentLength)
        } else {
            self.percentage = nil
        }
    }

}
