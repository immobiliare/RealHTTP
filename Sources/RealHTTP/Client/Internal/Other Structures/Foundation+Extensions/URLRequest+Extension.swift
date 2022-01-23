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

extension URLRequest {
    
    // MARK: - Additional Initialization

    /// Create a new instance of `URLRequest` with passed settings.
    ///
    /// - Parameters:
    ///   - url: url convertible value.
    ///   - method: http method to use.
    ///   - cachePolicy: cache policy to use.
    ///   - timeout: timeout interval.
    ///   - headers: headers to use.
    /// - Throws: throw an exception if url is not valid and cannot be converted to request.
    public init(url: URLConvertible, method: HTTPMethod,
                cachePolicy: URLRequest.CachePolicy,
                timeout: TimeInterval,
                headers: HTTPHeaders? = nil) throws {
        let url = try url.asURL()

        self.init(url: url)

        self.httpMethod = method.rawValue
        self.timeoutInterval = timeout
        self.allHTTPHeaderFields = headers?.asDictionary
    }
    
    // MARK: - Public Properties
    
    /// Return `true` if request has an associated stream.
    public var hasStream: Bool {
        httpBodyStream != nil
    }
    
    /// Returns the `httpMethod` as `HTTPMethod`
    public var method: HTTPMethod? {
        get { httpMethod.flatMap(HTTPMethod.init) }
        set { httpMethod = newValue?.rawValue }
    }
    
    /// Get the data of the body, read it from stream if necessary.
    public var body: Data? {
        guard let stream = httpBodyStream else {
            return httpBody // not a stream
        }
        
        var data = Data()
        stream.open()
        let bufferSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            data.append(buffer, count: read)
        }
        
        buffer.deallocate()
        stream.close()
        return data
    }
    
    // MARK: - Public Functions
    
    mutating internal func setHTTPBody(_ body: HTTPBody) throws {
        if let stream = body.content as? HTTPStreamContent {
            httpBodyStream = stream.inputStream(recreate: false)
        } else {
            httpBody = try body.content.encodedData()
        }
    }
    
    /// Request's header fields in forms of `HTTPHeaders` object.
    public var headers: HTTPHeaders {
        get {
            HTTPHeaders(rawDictionary: allHTTPHeaderFields)
        }
        set {
            allHTTPHeaderFields = newValue.asDictionary
        }
    }
    
}
