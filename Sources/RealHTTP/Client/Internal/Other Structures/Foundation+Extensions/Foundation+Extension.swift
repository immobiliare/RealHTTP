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

#if os(Linux)
import FoundationNetworking
#endif

#if os(macOS)
import CoreServices
#endif

#if os(iOS) || os(tvOS) || os(watchOS)
import MobileCoreServices
#endif

internal extension Bundle {
    
    private static let UnknownIdentifier = "Unknown"
    
    /// Bundle identifier.
    var bundleID: String {
        infoDictionary?["CFBundleIdentifier"] as? String ?? Bundle.UnknownIdentifier
    }
    
    /// Name of the executable which is running this library.
    var executableName: String {
        (infoDictionary?["CFBundleExecutable"] as? String) ??
            (ProcessInfo.processInfo.arguments.first?.split(separator: "/").last.map(String.init)) ??
            Bundle.UnknownIdentifier
    }
    
    /// Version of the application.
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? Bundle.UnknownIdentifier
    }
    
    /// Build of the application.
    var appBuild: String {
        infoDictionary?["CFBundleVersion"] as? String ?? Bundle.UnknownIdentifier
    }
    
    /// Name and version of the operating system.
    var osNameIdentifier: String {
        return "\(osName) \(osVersion)"
    }
    
    // Version of the operating system.
    var osVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
    
    /// Name of the operating system.
    var osName: String {
        #if os(iOS)
        #if targetEnvironment(macCatalyst)
        return "macOS(Catalyst)"
        #else
        return "iOS"
        #endif
        #elseif os(watchOS)
        return "watchOS"
        #elseif os(tvOS)
        return "tvOS"
        #elseif os(macOS)
        return "macOS"
        #elseif os(Linux)
        return "Linux"
        #elseif os(Windows)
        return "Windows"
        #else
        return "Unknown"
        #endif
    }
    
}

// MARK: - String Extension
extension String {
    
    // MARK: - Public Properties
    
    /// Create an RFC 3986 compliant string used to compose query string in URL.
    ///
    /// - Parameter string: source string.
    /// - Returns: String
    public var queryEscaped: String {
        self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowedSet) ?? self
    }
    
    // MARK: - Private Properties
    
    /// Return `true` if it's a valid full URL, `false` if it's relative URL.
    internal var isAbsoluteURL: Bool {
        if hasPrefix("localhost") {
            return true
        }
        
        let regEx = #"(\b(https?|ftp|file):\/\/)?[-A-Za-z0-9+&@#\/%?=~_|!:,.;]+[-A-Za-z0-9+&@#\/%=~_|]"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", argumentArray: [regEx])
        return predicate.evaluate(with: self)
    }
    
    /// Return the suggested mime type for path extension of the receiver.
    ///
    /// - Returns: String
    internal func suggestedMimeType() -> String {
        #if os(Linux)
            return HTTPContentType.octetStream.rawValue
        #else
        if let id = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, self as CFString, nil)?.takeRetainedValue(),
            let contentType = UTTypeCopyPreferredTagWithClass(id, kUTTagClassMIMEType)?.takeRetainedValue() {
            return contentType as String
        }

        return HTTPContentType.octetStream.rawValue
        #endif
    }
    
}

// MARK: - CharacterSet

extension CharacterSet {
    
    /// From Alamofire.
    /// Creates a CharacterSet from RFC 3986 allowed characters.
    ///
    /// RFC 3986 states that the following characters are "reserved" characters.
    ///
    /// - General Delimiters: ":", "#", "[", "]", "@", "?", "/"
    /// - Sub-Delimiters: "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="
    ///
    /// In RFC 3986 - Section 3.4, it states that the "?" and "/" characters should not be escaped to allow
    /// query strings to include a URL. Therefore, all "reserved" characters with the exception of "?" and "/"
    /// should be percent-escaped in the query string.
    public static let urlQueryAllowedSet: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        let encodableDelimiters = CharacterSet(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")

        return CharacterSet.urlQueryAllowed.subtracting(encodableDelimiters)
    }()
    
}

// MARK: - NSNumber Extension

extension NSNumber {
    
    internal var isBool: Bool {
        String(cString: objCType) == "c"
    }
    
}

// MARK: - InputStream Extension

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

// MARK: - Array String

extension Array where Element == String {
    
    internal func joinedWithAmpersands() -> String {
        joined(separator: "&")
    }
    
}

// MARK: - URL

extension URL: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: StaticString) {
        guard let url = URL(string: "\(value)") else {
            fatalError("Invalid URL string literal: \(value)")
        }
        self = url
    }
    
}

extension URL {
    
    /// Return suggested mime type for file at given URL.
    ///
    /// - Returns: String
    public func mimeType() -> String {
        self.pathExtension.suggestedMimeType()
    }
    
    // MARK: - Public Functions

    /// Returns the base URL string build with the scheme, host and path.
    /// For example:
    /// "https://www.apple.com/v1/test?param=test"
    /// would be "https://www.apple.com/v1/test"
    public var baseString: String? {
        guard let scheme = scheme, let host = host else { return nil }
        return scheme + "://" + host + path
    }

    // MARK: - Internal Functions
    
    /// Copy the temporary file for location in a non deletable path.
    ///
    /// - Parameters:
    ///   - task: task.
    ///   - request: request.
    /// - Returns: URL?
    internal func copyFileToDefaultLocation(task: URLSessionDownloadTask,
                                            forRequest request: HTTPRequest) -> URL? {

        let destinationURL = FileManager.default.temporaryFileLocation()
        do {
            try FileManager.default.copyItem(at: self, to: destinationURL)
            return destinationURL
        } catch {
            return nil
        }
    }
    
}

// MARK: - FileManager

extension FileManager {
    
    internal func temporaryFileLocation() -> URL {
        let fileName = UUID().uuidString
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)       
        return tmpURL
    }
    
}

// MARK: - Data

extension Data {
    
    /// Write to temporary file location.
    ///
    /// - Returns: URL
    internal func writeToTemporaryFile() -> URL? {
        do {
            let fileURL = FileManager.default.temporaryFileLocation()
            try write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }
    
}

// MARK: - Array

/// Same of += but for single items.
///
/// - Parameters:
///   - left: source array.
///   - right: right item to add.
/// - Returns: source array plus new item.
func += <V> ( left: inout [V], right: V) {
    left.append(right)
}

// MARK: - URLComponents

extension URLComponents {
    
    /// Get the value for a query item with givem key.
    ///
    /// - Parameter key: key.
    /// - Returns: `String?`
    public func valueForQueryItem(_ key: String) -> String? {
        queryItems?.first(where: { $0.name == key })?.value
    }
    
}

// MARK: - RWLock

internal class RWLock {
    
    // MARK: - Private Properties
    
    private let queue = DispatchQueue(label: "com.realhttp.httpdataloader.lock", attributes: .concurrent)
    
    // MARK: - Public Functions
    
    func concurrentlyRead<T>(_ block: (() throws -> T)) rethrows -> T {
        return try queue.sync {
            try block()
        }
    }
    
    func exclusivelyWrite(_ block: @escaping (() -> Void)) {
        queue.async(flags: .barrier) {
            block()
        }
    }
    
}
