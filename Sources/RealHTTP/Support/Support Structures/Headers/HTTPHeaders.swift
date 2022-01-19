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
//  Copyright ©2021 Immobiliare.it SpA.
//  Licensed under MIT License.
//

import Foundation

/// An order-preserving and case-insensitive representation of HTTP headers.
public struct HTTPHeaders: ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral,
                            Sequence, Collection,
                            CustomStringConvertible,
                            Equatable, Hashable,
                            Sendable {
    // MARK: - Private Properties
    
    /// Storage for headers.
    private var headers = [HTTPHeader]()
    
    // MARK: - Initialization
    
    /// The default set of `HTTPHeaders` used by the library.
    /// It includes encoding, language and user agent.
    public static var `default`: HTTPHeaders {
        HTTPHeaders(headers: [
            .defaultAcceptEncoding,
            .defaultAcceptLanguage,
            .defaultUserAgent
        ])
    }
    
    /// Initialize a new HTTPHeaders storage with given data.
    ///
    /// NOTE: It's case insentive so duplicate names are collapsed into the last name
    /// and value encountered.
    /// - Parameter headers: headers.
    public init(headers: [HTTPHeader] = []) {
        headers.forEach {
            set($0)
        }
    }
    
    /// Create a new instance of HTTPHeaders from a dictionary of key,values
    ///
    /// NOTE: It's case insentive so duplicate names are collapsed into the last name
    /// and value encountered.
    /// - Parameter headersDictionary: headers dictionary.
    public init(rawDictionary: [String: String]?) {
        rawDictionary?.forEach {
            set(HTTPHeader(name: $0.key, value: $0.value))
        }
    }
    
    /// Create a new instance of HTTPHeaders from a dictionary of key,values where
    /// key is the `HTTPHeaderField` and not a raw string.
    ///
    /// - Parameter headersDictionary: headers dictionary.
    public init(_ headersDictionary: [HTTPHeaderField: String]?) {
        headersDictionary?.forEach {
            set(HTTPHeader(name: $0.key, value: $0.value))
        }
    }
    
    /// Initialize by passing a `ExpressibleByArrayLiteral` array.
    ///
    /// - Parameter elements: elements.
    public init(arrayLiteral elements: HTTPHeader...) {
        self.init(headers: elements)
    }
    
    /// Initialize by passing a `ExpressibleByDictionaryLiteral` array.
    ///
    /// - Parameter headersDictionary: elements.
    public init(dictionaryLiteral headersDictionary: (String, String)...) {
        headersDictionary.forEach {
            set($0.0, $0.1)
        }
    }
    
    // MARK: - Sequence, Collection Conformance
    
    public func makeIterator() -> IndexingIterator<[HTTPHeader]> {
        headers.makeIterator()
    }
    
    public var startIndex: Int {
        headers.startIndex
    }

    public var endIndex: Int {
        headers.endIndex
    }

    public subscript(position: Int) -> HTTPHeader {
        headers[position]
    }

    public func index(after i: Int) -> Int {
        headers.index(after: i)
    }
    
    // MARK: - Add Headers Functions
    
    /// Add of a new header to the list.
    /// NOTE: It's case insensitive.
    ///
    /// - Parameters:
    ///   - name: name of the header.
    ///   - value: value of the header.
    public mutating func set(_ name: String, _ value: String) {
        set(HTTPHeader(name: name, value: value))
    }
    
    /// Add of a new header to the list.
    ///
    /// - Parameters:
    ///   - field: field.
    ///   - value: value.
    public mutating func set(_ field: HTTPHeaderField, _ value: String) {
        set(HTTPHeader(name: field.rawValue, value: value))
    }
    
    /// Update the headers value by adding a new header.
    /// NOTE: It's case insensitive.
    ///
    /// - Parameter header: header to add.
    public mutating func set(_ header: HTTPHeader) {
        guard let index = headers.index(of: header.name) else {
            headers.append(header)
            return
        }
        
        headers.replaceSubrange(index...index, with: [header])
    }
    
    /// Update the headers with the ordered list passed.
    /// NOTE: It's case insentive.
    ///
    /// - Parameter headers: headers to add.
    public mutating func set(_ headers: [HTTPHeader]) {
        headers.forEach {
            set($0)
        }
    }
    
    /// Add headers from a dictionary.
    ///
    /// - Parameter headers: headers
    public mutating func set(_ headers: [HTTPHeaderField: String]) {
        headers.enumerated().forEach {
            set(HTTPHeader(name: $0.element.key.rawValue, value: $0.element.value))
        }
    }
    
    // MARK: - Remove Headers Functions
    
    /// Case-insensitively removes an `HTTPHeader`, if it exists, from the instance.
    ///
    /// - Parameter name: The name of the `HTTPHeader` to remove.
    public mutating func remove(name: String) {
        guard let index = headers.index(of: name) else {
            return
        }

        headers.remove(at: index)
    }

    /// Case-insensitively find a header's value passing the name.
    ///
    /// - Parameter name: name of the header, search is not case sensitive.
    /// - Returns: String or nil if ket does not exists.
    public func value(for name: String) -> String? {
        guard let index = headers.index(of: name) else {
            return nil
        }

        return headers[index].value
    }
    
    // MARK: - Other Functions
    
    /// Sort the current instance by header name.
    /// NOTE: It's case insentive.
    public mutating func sort() {
        headers.sort {
            $0.name.lowercased() < $1.name.lowercased()
        }
    }

    /// Convert the object to a dictionary of key,value.
    /// Note: duplicate values may be overriden and the order is not preserved.
    public var asDictionary: [String: String] {
        let namesAndValues = headers.map {
            ($0.name, $0.value)
        }

        return Dictionary(namesAndValues, uniquingKeysWith: { _, last in last })
    }
    
    /// Subscript access to the value of an header.
    /// NOTE: It's case insentive.
    ///
    /// - Parameter name: The name of the header.
    public subscript(_ name: String) -> String? {
        get {
            value(for: name)
        }
        set {
            if let value = newValue {
                set(name, value)
            } else {
                remove(name: name)
            }
        }
    }
    
    public subscript(_ key: HTTPHeaderField) -> String? {
        get {
            self[key.rawValue]
        }
        set {
            self[key.rawValue] = newValue
        }
    }
    
    /// Description of the headers.
    public var description: String {
        headers.map {
            $0.description
        }.joined(separator: "\n")
    }
    
    static func + (left: HTTPHeaders, right: HTTPHeaders) -> HTTPHeaders {
        HTTPHeaders(headers: left.headers + right.headers)
    }

}

// MARK: HTTPHeaders (HTTPURLResponse Extension)

extension HTTPURLResponse {
    
    /// Returns `allHeaderFields` as `HTTPHeaders`.
    public var headers: HTTPHeaders {
        HTTPHeaders(rawDictionary: allHeaderFields as? [String: String])
    }
    
}

// MARK: HTTPHeaders (URLSessionConfiguration Extension)

extension URLSessionConfiguration {
    
    /// `httpAdditionalHeaders` as `HTTPHeaders` object.
    public var headers: HTTPHeaders {
        get {
            HTTPHeaders(rawDictionary: httpAdditionalHeaders as? [String: String])
        }
        set {
            httpAdditionalHeaders = newValue.asDictionary
        }
    }
    
}


// MARK: - Array Extensions

extension Array where Element == HTTPHeader {
        
    /// Search for index of an HTTPHeader's field inside the list.
    /// Search is made as case insensitive.
    ///
    /// - Parameter name: name of the header.
    /// - Returns: Int?
    internal func index(of name: String) -> Int? {
        let lowercasedName = name.lowercased()
        return firstIndex { $0.name.lowercased() == lowercasedName }
    }
    
}
