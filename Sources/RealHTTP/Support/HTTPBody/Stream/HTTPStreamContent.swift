//
//  File.swift
//  
//
//  Created by Daniele Margutti on 26/12/21.
//

import Foundation

/// Allows to send stream content to an HTTPRequest as content property.
public final class HTTPStreamContent: HTTPEncodableBody {
    
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
    
    internal func inputStream(recreate: Bool) -> InputStream? {
        if let existingStream = self.inputStream, !recreate {
            return existingStream
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
        
        return inputStream
    }
    
    // MARK: - Protocol Conformance
    
    public func encodedData() throws -> Data {
        Data()
    }
    
}

// MARK: - HTTPStreamContent (Source)

extension HTTPStreamContent {
    
    /// Source of stream:
    /// - `fileURL`: local file url.
    /// - `data`: data content.
    public enum Source {
        case fileURL(URL)
        case data(Data)
    }
    
}
