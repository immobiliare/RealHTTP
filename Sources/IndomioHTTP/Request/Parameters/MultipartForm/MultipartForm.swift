//
//  IndomioNetwork
//
//  Created by the Mobile Team @ ImmobiliareLabs
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Copyright ©2021 Immobiliare.it SpA. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

/// Allows to create a multipart/form-data for uploads fo forms.
open class MultipartForm: HTTPEncodableParameters {
    
    // MARK: - Public Properties
    
    /// The `Content-Type` header value containing the boundary used to generate the `multipart/form-data`.
    open lazy var contentType = "multipart/form-data; boundary=\(boundary.id)"
        
    /// The length of multipart form.
    public var contentLength: UInt64 {
        formItems.reduce(0) {
            $0 + $1.length
        }
    }
    
    /// The boundary used to separate the body parts in the encoded form data.
    public let boundary: Boundary
    
    // MARK: - Private Properties
    
    /// Body contents of the form.
    private var formItems = [MultipartFormItem]()
    
    // MARK: - Initialization
    
    /// Initialize a new multipart form.
    ///
    /// - Parameter boundary: boundary, if `nil` a value is generated automatically.
    public init(boundary: Boundary? = nil) {
        self.boundary = boundary ?? Boundary()
    }
    
    // MARK: - Add Items
    
    /// Add body part from the data and appends it to the form.
    ///
    /// - Parameters:
    ///   - data: data to add.
    ///   - name: Name to associate with the `Data` in the `Content-Disposition` HTTP header.
    ///   - fileName: Filename to associate with the `Data` in the `Content-Disposition` HTTP header.
    ///   - mimeType: IME type to associate with the data in the `Content-Type` HTTP header.
    public func add(data: Data, name: String, fileName: String? = nil, mimeType: String? = nil) {
        let formHeaders = formItemHeaders(name: name, fileName: fileName, mimeType: mimeType)
        let stream = InputStream(data: data)
        let length = UInt64(data.count)
        
        add(stream: stream, withLength: length, headers: formHeaders)
    }
    
    /// Add body part from the string and appends it to the form.
    ///
    /// - Parameters:
    ///   - string: string value, it will converted to utf8 binary data.
    ///   - name: Name to associate with the `Data` in the `Content-Disposition` HTTP header.
    /// - Throws: throw an exeption if conversion fails.
    public func add(string: String, name: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw IndomioHTTPError.multipartFailedStringEncoding
        }
        
        add(data: data, name: name)
    }
    
    /// Add body part from the file and appends it to the form.
    ///
    /// - Parameters:
    ///   - fileURL: local file `URL`  whose content will be encoded and sent.
    ///   - name: Name to associate with the file content in the `Content-Disposition` HTTP header.
    /// - Throws: throw an exception if something fails reading file or file it's invalid.
    public func add(fileURL: URL, name: String) throws {
        let fileName = fileURL.lastPathComponent
        let fileExtension = fileURL.pathExtension
        let mimeType = fileExtension.suggestedMimeType()

        guard !fileName.isEmpty, // filename is not empty
              !fileExtension.isEmpty, // extension is set
              fileURL.isFileURL, // is it a file?
              try fileURL.checkPromisedItemIsReachable() else { // is file reachable
            throw IndomioHTTPError.multipartInvalidFile(fileURL)
        }
        
        let formHeaders = formItemHeaders(name: name, fileName: fileName, mimeType: mimeType)
        
        let fileSize = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as! NSNumber
        
        guard let fileStream = InputStream(url: fileURL) else {
            throw IndomioHTTPError.multipartInvalidFile(fileURL)
        }
        
        add(stream: fileStream, withLength: fileSize.uint64Value, headers: formHeaders)
    }
    
    /// Add body part from the stream and appends it to the form.
    ///
    /// - Parameters:
    ///   - stream: `InputStream` to encode into the instance.
    ///   - length: Length, in bytes, of the stream.
    ///   - name: Name to associate with the stream content in the `Content-Disposition` HTTP header.
    ///   - fileName: Filename to associate with the stream content in the `Content-Disposition` HTTP header.
    ///   - mimeType: MIME type to associate with the stream content in the `Content-Type` HTTP header.
    public func add(stream: InputStream, withLength length: UInt64, name: String, fileName: String, mimeType: String) {
        let formHeaders = formItemHeaders(name: name, fileName: fileName, mimeType: mimeType)
        add(stream: stream, withLength: length, headers: formHeaders)
    }
    
    // MARK: - Encoding
    
    /// Encode the multipart form data and produce the output to be attached to the URLRequest.
    ///
    /// - Throws: throw an exception if encoding fails.
    /// - Returns: Data
    public func encode() throws -> Data {
        var data = Data()

        try formItems.enumerated().forEach {
            let kind: Boundary.Kind = ($0.offset == 0 ? .start : ($0.offset == (formItems.count-1) ? .end : .encapsulated))
            let encodedFormItem = try encodeFormItem($0.element, kind: kind)
            data.append(encodedFormItem)
        }
        
        return data
    }
    
    // MARK: - Private Functions
    
    /// Encode a single item of the multipart form.
    ///
    /// - Parameters:
    ///   - item: item to encode.
    ///   - kind: position of the multipart form item into the list.
    ///
    /// - Throws: throw an exception if something fails.
    /// - Returns: Data
    private func encodeFormItem(_ item: MultipartFormItem, kind: Boundary.Kind) throws -> Data {
        var data = Data()

        // Boundary section
        let boundarySection = Data(boundary.boundaryStringFor(.start).utf8)
        data.append(boundarySection)

        // Header section with content-disposition data
        let headersSection = Data(item.headers.asMultipartFormItemHeaders().utf8)
        data.append(headersSection)
        
        // Stream of data
        let streamSection = try item.encodedData()
        data.append(streamSection)
        
        // Final boundary
        if kind == .end {
            let boundaryEndSection = Data(boundary.boundaryStringFor(.end).utf8)
            data.append(boundaryEndSection)
        }
        
        return data
    }
    
    /// Add body part from the stream and appends it to the form.
    ///
    /// - Parameters:
    ///   - stream: `InputStream` to encode into the instance.
    ///   - length: Length, in bytes, of the stream.
    ///   - headers: headers to append
    public func add(stream: InputStream, withLength length: UInt64, headers: HTTPHeaders) {
        let item = MultipartFormItem(stream: stream, length: length, headers: headers)
        formItems.append(item)
    }
    
    
    /// Generate the `Content-Disposition` for a single form item.
    ///
    /// - Parameters:
    ///   - name: name of the item.
    ///   - fileName: filename.
    ///   - mimeType: mimetype.
    /// - Returns: HTTPHeaders
    private func formItemHeaders(name: String, fileName: String? = nil, mimeType: String? = nil) -> HTTPHeaders {
        var contentDisposition = "form-data; name=\"\(name)\""
        if let fileName = fileName {
            contentDisposition += "; filename=\"\(fileName)\""
        }

        var headers: HTTPHeaders = [.contentDisposition(contentDisposition)]
        if let mimeType = mimeType {
            headers.add(.contentType(mimeType))
        }

        return headers
    }

    
}

// MARK: - MultipartFormItem

/// A single item of the MultipartForm object.
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
    
    // MARK: - Encoding
    
    /// Encode a stream and produce the Data.
    ///
    /// - Parameter item: item to encode.
    /// - Throws: throw an exception if encoding fails.
    /// - Returns: Data
    internal func encodedData() throws -> Data {
        stream.open()
        
        defer {
            stream.close()
        }
        
        var data = Data()
        
        /// The optimal read/write buffer size for input/output streams is 1024bytes (1KB).
        /// <https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/Streams/Articles/ReadingInputStreams.html>
        let bufferSize = 1024
        
        while stream.hasBytesAvailable {
            var buffer = [UInt8](repeating: 0, count: bufferSize)
            let bytesRead = stream.read(&buffer, maxLength: bufferSize)

            if let error = stream.streamError {
                throw IndomioHTTPError.multipartStreamReadFailed(error)
            }

            guard bytesRead > 0 else {
                break
            }

            data.append(buffer, count: bytesRead)
        }
        
        return data
    }
    
}


// MARK: - HTTPHeaders Extensions

fileprivate extension HTTPHeaders {
    
    /// Encoded HTTPHeaders to be contained into the `Content-Disposition` of a single multipart form item.
    ///
    /// - Returns: Data
    func asMultipartFormItemHeaders() -> String {
        let clrf = MultipartForm.Boundary.crlf
        
        return map {
            "\($0.name): \($0.value)\(clrf)"
        }.joined() + clrf
    }
    
}
