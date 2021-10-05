//
//  IndomioHTTP
//
//  Created by the Mobile Team @ ImmobiliareLabs
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Copyright ©2021 Immobiliare.it SpA. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

/// Allows to send stream content to an HTTPRequest as content property.
public class HTTPStreamContent: HTTPRequestEncodableData {
    
    // MARK: - Private Properties
    
    /// Input stream.
    private var inputStream: InputStream?
    
    /// Length of the stream
    private var length: UInt64 = 0
    
    // MARK: - Public Properties
    
    /// Source of the stream
    public let source: Source
    
    private init(source: Source) {
        self.source = source
    }
    
    // MARK: - Initialization
    
    /// Initialize a new stream from a local file.
    ///
    /// - Parameter fileURL: file url.
    public convenience init(fileURL: URL) {
        self.init(source: .fileURL(fileURL))
    }
    
    /// Initialize a new stream from a data.
    ///
    /// - Parameter data: data.
    public convenience init(data: Data) {
        self.init(source: .data(data))
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
    
    public func encodeParametersIn(request: inout URLRequest) throws {
        request.httpBodyStream = inputStream(recreate: false)
        request.headers.set([
            .connection: "Keep-Alive",
            .contentLength: String(length),
        ])
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
