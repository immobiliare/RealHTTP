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

extension Data {
    
    /// Convert a data to a string using utf8 encoding.
    public var asString: String? {
        asString(encoding: .utf8)
    }
    
    /// Convert a data to a string.
    ///
    /// - Parameter encoding: encoding to use.
    /// - Returns: String?
    public func asString(encoding: String.Encoding) -> String? {
        String(data: self, encoding: encoding)
    }
    
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
    
    /// Returns the redirect location from the raw HTTP response if exists.
    internal var redirectLocation: URL? {
        let locationComponent = String(data: self, encoding: String.Encoding.utf8)?.components(separatedBy: "\n").first(where: { (value) -> Bool in
            return value.contains("Location:")
        })
        
        guard let redirectLocationString = locationComponent?.components(separatedBy: "Location:").last,
                let redirectLocation = URL(string: redirectLocationString.trimmingCharacters(in: NSCharacterSet.whitespaces)) else {
            return nil
        }
        return redirectLocation
    }
    
}
