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
    
    /// Allows to send stream content to an HTTPRequest as content property.
    public class StreamContent: HTTPSerializableBody {
        
        // MARK: - Private Properties
        
        /// Input stream.
        private var inputStream: InputStream?
        
        // MARK: - Public Properties
        
        /// Source of the stream
        public let source: Source
        
        /// Length of the stream
        public private(set) var length: UInt64 = 0
        
        // MARK: - Initialization
        
        /// Initialize a new source of stream.
        ///
        /// - Parameter source: source.
        internal init(source: Source) {
            self.source = source
        }
        
        // MARK: - Internal Functions
        
        internal func inputStream(recreate: Bool) -> (stream: InputStream?, additionalHeaders: HTTPHeaders?) {
            if let existingStream = self.inputStream, !recreate {
                return (existingStream, .init([
                    .contentLength: String(length)
                ]))
            }
            
            switch source {
            case .data(let data):
                self.inputStream = InputStream(data: data)
                self.length = UInt64(data.count)
            case .fileURL(let fileURL):
                self.inputStream = InputStream(fileAtPath: fileURL.path)
                let fileSize = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? NSNumber
                self.length = (fileSize ?? NSNumber(0)).uint64Value
            }
            
            return (inputStream, .init([
                .contentLength: String(length)
            ]))
        }
        
        // MARK: - Protocol Conformance
        
        public func serializeData() throws -> (data: Data, additionalHeaders: HTTPHeaders?) {
            (Data(), .init([
                .contentLength: String(length)
            ]))
        }
        
    }
    
}

// MARK: - HTTPStreamContent (Source)

extension HTTPBody.StreamContent {
    
    /// Source of stream:
    /// - `fileURL`: local file url.
    /// - `data`: data content.
    public enum Source {
        case fileURL(URL)
        case data(Data)
    }
    
}
