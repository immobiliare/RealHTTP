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
    
    /// Return the curl string which represent the request.
    /// 
    /// NOTE:
    /// Logging URL requests in whole may expose sensitive data,
    /// or open up possibility for getting access to your user data,
    /// so make sure to disable this feature for production builds!
    public var cURLString: String {
        #if !DEBUG
        return ""
        #else
        var result = "curl -k "
        
        if let method = httpMethod {
            result += "-X \(method) \\\n"
        }
        
        if let headers = allHTTPHeaderFields {
            for (header, value) in headers {
                result += "-H \"\(header): \(value)\" \\\n"
            }
        }
        
        if let body = httpBody, !body.isEmpty, let string = String(data: body, encoding: .utf8), !string.isEmpty {
            result += "-d '\(string)' \\\n"
        }
        
        if let url = url {
            result += url.absoluteString
        }
        
        return result
        #endif
    }
    
}

// MARK: - Data

extension Data {
    
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

        return "application/octet-stream"
    }
    
}

// MARK: - Array

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

extension URL {
    
    func copyFileToDefaultLocation(task: URLSessionDownloadTask, forRequest request: HTTPRequestProtocol) -> URL? {
        let fManager = FileManager.default
        
        var destURL: URL? = request.resumeDataURL
        if destURL == nil {
            let fileName = "download-id-\(task.taskIdentifier)"
            let documentsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as NSString
            destURL = URL(fileURLWithPath: documentsDir.appendingPathComponent(fileName))
        }
        
        guard let destURL = destURL else {
            return nil
        }
        
        do {
            try fManager.copyItem(at: self, to: destURL)
            return destURL
        } catch {
            return nil
        }
    }
    
}
