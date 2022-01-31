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

/// `HTTPProgress` is used to send periodic updates about an upload or a download
/// session. It contains all the relevant information about the current state of the operation.
public struct HTTPProgress: Comparable, Equatable {
    
    // MARK: - Support Structures
    
    /// Kind of operation which identify the progress.
    /// - `upload`: upload operation to remote server.
    /// - `download`: download operation from a remote server.
    /// - `failed`: download failed. Typically inside `partialData` you can found resumable data to use with
    ///             `HTTPRequest`'s `partialData` to resume the download.
    /// - `resumed`: this evenet is triggered when `URLSession` found a way to resume the download from partial data.
    public enum Event {
        case upload
        case download
        case failed
        case resumed
    }
    
    // MARK: - Public Properties
    
    /// Kind of transfer.
    public internal(set) var event: Event = .download
    
    /// Progress object which contains additional informations.
    public let progress: Progress?
    
    /// The number of bytes sent/received since the last time this delegate method was called.
    public let currentLength: Int64
    
    /// The expected length of the body data.
    /// Depending by the server this value can be 0 if no expected length can be determined
    /// (ie. by reading the `Content-Length` header .
    /// Local uploades includes this value automatically when made using the library.
    public let expectedLength: Int64
    
    /// The percentage of the progression.
    /// When not available value is 0.0.
    public let percentage: Double
    
    /// If a download fails you can receive a `.failed` `HTTProgress` update where this value
    /// is not `nil`. You can save this data and pass it to `partialData` of a new `HTTPRequest`
    /// in order to attempt to resume download.
    public let partialData: Data?
    
    // MARK: - Initialization
    
    /// Initialize a new progress structure with the data.
    ///
    /// - Parameters:
    ///   - event: kind of event which is represented by the progress object.
    ///   - progress: progress instance when available.
    ///   - current: current downloaded/uploaded bytes (valid values are different from 0).
    ///   - expected: expected bytes (if 0 or -1 no estimation is available).
    ///   - partialData: partially downloaded data in case it's available and operation is `failed`.
    internal init(event: Event = .download,
                  progress: Progress? = nil,
                  currentLength: Int64, expectedLength: Int64,
                  partialData: Data? = nil) {
        self.event = event
        self.progress = progress
        self.currentLength = currentLength
        self.expectedLength = expectedLength
        self.partialData = partialData
        
        if expectedLength != NSURLSessionTransferSizeUnknown, expectedLength != 0 {
            let slice = Double(1.0)/Double(expectedLength)
            self.percentage = slice*Double(currentLength)
        } else {
            self.percentage = 0
        }
    }
    
    public static func < (lhs: HTTPProgress, rhs: HTTPProgress) -> Bool {
        lhs.percentage < rhs.percentage
    }

}
