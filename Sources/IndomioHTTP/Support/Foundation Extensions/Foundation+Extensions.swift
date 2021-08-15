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
import CoreServices

// MARK: - Swift.Error

extension Swift.Error {
    
    /// Return `true` when error is related to the connection.
    var isMissingConnection: Bool {
        switch self {
        case URLError.notConnectedToInternet,
             URLError.networkConnectionLost,
             URLError.cannotLoadFromNetwork:
             return true
        default:
            return false
        }
    }
    
}

// MARK: - URLRequest

extension URLRequest {
    
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
    
}

// MARK: - Data

extension Data {
    
    /// Create a new Data with the contents of file at given url.
    ///
    /// - Parameter fileURL: file location, must be local and must be exists, otherwise it will return nil.
    /// - Returns: Data?
    static func fromURL(_ fileURL: URL?) -> Data? {
        guard let fileURL = fileURL else { return nil }
        
        do {
            return try Data(contentsOf: fileURL)
        } catch {
            return nil
        }
    }
    
    /// Convert a data to a string.
    ///
    /// - Parameter encoding: encoding to use, `utf8` if not specified.
    /// - Returns: String?
    public func asString(encoding: String.Encoding = .utf8) -> String? {
        String(data: self, encoding: encoding)
    }
    
    /// Print a json value for a given data. If not convertible `nil` is retuened.
    ///
    /// - Parameters:
    ///   - options: options, `prettyPrinted` if not specified.
    ///   - encoding: encoding to use, `utf8` if not specified.
    /// - Returns: String?
    public func jsonString(options: JSONSerialization.WritingOptions = [.prettyPrinted],
                           encoding: String.Encoding = .utf8) -> String? {
        do {
            let json = try JSONSerialization.jsonObject(with: self, options: [])
            let value = try JSONSerialization.data(withJSONObject: json, options: options).asString(encoding: encoding)
            return value
        } catch {
            return nil
        }
    }
    
    /// JSON object.
    ///
    /// - Returns: T?
    public func json<T>() -> T? {
        do {
            let json = try JSONSerialization.jsonObject(with: self, options: [])
            return json as? T
        } catch {
            return nil
        }
    }
    
}

// MARK: - NSNumber

extension NSNumber {
    
    internal var isBool: Bool {
        String(cString: objCType) == "c"
    }
    
}

// MARK: - String

extension String {
    
    /// Create an RFC 3986 compliant string used to compose query string in URL.
    ///
    /// - Parameter string: source string.
    /// - Returns: String
    public var queryEscaped: String {
        self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowedSet) ?? self
    }
    
    /// Return the suggested mime type for path extension of the receiver.
    ///
    /// - Returns: String
    internal func suggestedMimeType() -> String {
        if let id = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, self as CFString, nil)?.takeRetainedValue(),
            let contentType = UTTypeCopyPreferredTagWithClass(id, kUTTagClassMIMEType)?.takeRetainedValue() {
            return contentType as String
        }

        return HTTPContentType.octetStream.rawValue
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

extension Array where Element == String {
    
    internal func joinedWithAmpersands() -> String {
        joined(separator: "&")
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

// MARK: - Bundle

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

// MARK: - String + URL Extensions

extension String {
    
    // MARK: - Public Functions
    
    /// Return `true` if URL is not an absolute URL.
    public var isRelative: Bool {
        String.aboluteRegEx.numberOfMatches(in: self, options: [], range: NSRange(self.startIndex..., in: self)) == 0
    }
    
    // MARK: - Internal Properties

    /// Regular expression to validate absolute URL
    /// See <https://regex101.com/r/nR2yL6/3>
    /// See <https://stackoverflow.com/a/31991870>
    static private var aboluteRegEx: NSRegularExpression {
        try! NSRegularExpression(pattern: "(?:^[a-z][a-z0-9+.-]*:|\\/\\/)", options: .caseInsensitive)
    }
    
}

// MARK: - URL

extension URL {
    
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
    internal func copyFileToDefaultLocation(task: URLSessionDownloadTask, forRequest request: HTTPRequestProtocol) -> URL? {
        let fManager = FileManager.default
        
        let fileName = UUID().uuidString
        let documentsDir = NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true).first! as NSString
        let destinationURL = URL(fileURLWithPath: documentsDir.appendingPathComponent(fileName))
        
        do {
            try fManager.copyItem(at: self, to: destinationURL)
            return destinationURL
        } catch {
            return nil
        }
    }
    
}

// MARK: - Data Extension for HTTP Stub

extension Data {
    
    /// Returns the redirect location from the raw HTTP response if exists.
    internal var redirectLocation: URL? {
        let locationComponent = String(data: self, encoding: String.Encoding.utf8)?.components(separatedBy: "\n").first(where: { (value) -> Bool in
            return value.contains("Location:")
        })
        
        guard let redirectLocationString = locationComponent?.components(separatedBy: "Location:").last, let redirectLocation = URL(string: redirectLocationString.trimmingCharacters(in: NSCharacterSet.whitespaces)) else {
            return nil
        }
        return redirectLocation
    }
    
}
