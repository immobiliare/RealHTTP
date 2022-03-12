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

extension HTTPBody {
    
    /// Allows to create a multipart/form-data for uploads fo forms.
    public class MultipartForm: HTTPSerializableBody {
        
        // MARK: - Public Properties
        
        /// The `Content-Type` header value containing the boundary used to generate the `multipart/form-data`.
        public lazy var contentType = "multipart/form-data; boundary=\(boundary.id)"
        
        /// The length of multipart form.
        public var contentLength: UInt64 {
            formItems.reduce(0) {
                $0 + $1.length
            }
        }
        
        /// The id of the boundary
        public var boundaryID: String {
            boundary.id
        }
        
        /// A string that is optionally inserted before the first boundary delimiter.
        /// Can be used as an explanatory note for
        /// recipients who read the message with pre-MIME software,
        /// since such notes will be ignored by MIME-compliant software.
        public var preamble: String? = nil
        
        // MARK: - Private Properties
        
        /// The boundary used to separate the body parts in the encoded form data.
        internal let boundary: Boundary
        
        /// Body contents of the form.
        private var formItems = [MultipartForm.Item]()
        
        // MARK: - Initialization
        
        /// Initialize a new multipart form.
        ///
        /// - Parameter boundary: boundary identifier, if `nil` it will generated automatically
        public init(boundary id: String? = nil) {
            self.boundary = .init(id)
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
                throw HTTPError(.multipartFailedStringEncoding)
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
                      throw HTTPError(.multipartInvalidFile)
                  }
            
            let formHeaders = formItemHeaders(name: name, fileName: fileName, mimeType: mimeType)
            
            let fileSize = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as! NSNumber
            
            guard let fileStream = InputStream(url: fileURL) else {
                throw HTTPError(.multipartInvalidFile)
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
                
        // MARK: - Private Functions
        
        /// Encode the multipart form data and produce the output to be attached to the URLRequest.
        ///
        /// - Throws: throw an exception if encoding fails.
        /// - Returns: Data
        public func serializeData() async throws -> (data: Data, additionalHeaders: HTTPHeaders?) {
            var data = Data()
            
            if let preamble = self.preamble?.data(using: .utf8) {
                data.append(preamble + Boundary.crlfData)
                data.append(Boundary.crlfData)
            }
            
            if formItems.isEmpty {
                data.append(boundary.delimiterData)
                data.append(Boundary.crlfData)
                data.append(Boundary.crlfData)
            } else {
                for formItem in formItems {
                    data.append(boundary.delimiterData + Boundary.crlfData)
                    if formItem.headers.isEmpty == false {
                        let headerData = Data(formItem.headers.asMultipartFormItemHeaders().utf8)
                        data.append(headerData)
                    }
                    
                    data.append(Boundary.crlfData)
                    let streamSection = try formItem.encodedData()
                    data.append(streamSection + Boundary.crlfData)
                }
            }
            
            return (data, .init([
                .contentType : contentType
            ]))
        }
        
        /// Add body part from the stream and appends it to the form.
        ///
        /// - Parameters:
        ///   - stream: `InputStream` to encode into the instance.
        ///   - length: Length, in bytes, of the stream.
        ///   - headers: headers to append
        public func add(stream: InputStream, withLength length: UInt64, headers: HTTPHeaders) {
            let item = MultipartForm.Item(stream: stream, length: length, headers: headers)
            formItems.append(item)
        }
        
        /// Add the content of file as stream to the multipart form item.
        ///
        /// - Parameters:
        ///   - fileURL: local file URL.
        ///   - headers: headers to append
        public func add(fileStream fileURL: URL, headers: HTTPHeaders) {
            let fileSize = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? NSNumber
            let length = (fileSize ?? NSNumber(0)).uint64Value
            guard let stream = InputStream(fileAtPath: fileURL.path) else {
                return
            }
            
            add(stream: stream, withLength: length, headers: headers)
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
                headers.set(.contentType(mimeType))
            }
            
            return headers
        }
        
        
    }
    
}

// MARK: - HTTPHeaders Extensions

fileprivate extension HTTPHeaders {
    
    /// Encoded HTTPHeaders to be contained into the `Content-Disposition` of a single multipart form item.
    ///
    /// - Returns: Data
    func asMultipartFormItemHeaders() -> String {
        let clrf = HTTPBody.MultipartForm.Boundary.crlf
        
        return map {
            "\($0.name.rawValue): \($0.value)\(clrf)"
        }.joined()
    }
    
}
