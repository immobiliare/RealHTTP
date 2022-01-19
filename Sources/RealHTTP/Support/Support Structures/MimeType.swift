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

public struct MIMEType: Equatable, Hashable, Codable, RawRepresentable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public struct Parameter<Value: HTTPFormattible> {
        public struct Key {
            let name: String
        }

        public let key: Key
        public let value: Value

        public init(key: Key, value: Value) {
            self.key = key
            self.value = value
        }
    }

    public func appending<Value>(_ key: Parameter<Value>.Key, value: Value) -> MIMEType {
        appending(Parameter<Value>(key: key, value: value))
    }

    func appending<Value>(_ parameters: [Parameter<Value>]) -> MIMEType {
        var mimeType = self
        mimeType.append(parameters)
        return mimeType
    }

    func appending<Value>(_ parameter: Parameter<Value>) -> MIMEType {
        appending([parameter])
    }

    mutating func append<Value>(_ key: Parameter<Value>.Key, value: Value) {
        append(Parameter<Value>(key: key, value: value))
    }

    mutating func append<Value>(_ parameter: Parameter<Value>) {
        append([parameter])
    }

    mutating func append<Value>(_ parameters: [Parameter<Value>]) {
        for parameter in parameters {
            rawValue.append("; \(parameter.key.name)=\"\(parameter.value.httpFormatted())\"")
        }
    }
    
    public struct CharacterSet: HTTPFormattible {
        public let identifier: String

        public func httpFormatted() -> String {
            identifier
        }
    }
}

extension MIMEType: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

extension MIMEType {
    public struct Group<Parent> {}

    public enum Application {}
    public static let application = Application.self

    public enum Text {}
    public static let text = Text.self

    public enum Font {}
    public static let font = Font.self

    public enum Image {}
    public static let image = Image.self

    public static let formData: Self = "form-data"
    public static let multipart: Self = "multipart/form-data"
}

extension MIMEType.Application {
    public static let wwwForm: MIMEType = "application/x-www-form-urlencoded"
    public static let json: MIMEType = "application/json"
    public static let pdf: MIMEType = "application/pdf"
    public static let zip: MIMEType = "application/zip"
    public static let gzip: MIMEType = "application/gzip"
}

extension MIMEType.Text {
    public static let html: MIMEType = "text/html"
    public static let csv: MIMEType = "text/csv"
    public static let xml: MIMEType = "text/xml"
    public static let javascript: MIMEType = "text/javascript"
    public static let plain: MIMEType = "text/plain"
}

extension MIMEType.Font {
    public static let otf: MIMEType = "font/otf"
    public static let ttf: MIMEType = "font/ttf"
    public static let woff: MIMEType = "font/woff"
    public static let woff2: MIMEType = "font/woff2"
}

extension MIMEType.Image {
    public static let jpg: MIMEType = "image/jpeg"
    public static let gif: MIMEType = "image/gif"
    public static let png: MIMEType = "image/png"
    public static let webp: MIMEType = "image/webp"
}

extension MIMEType.CharacterSet: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(identifier: value)
    }

    public static let ascii: Self = "ascii"
    public static let utf8: Self = "utf-8"
    public static let utf16: Self = "utf-16"
}

extension MIMEType.Parameter.Key: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(name: value)
    }
}

extension MIMEType.Parameter.Key where Value == MIMEType.CharacterSet {
    public static let characterSet: Self = "charset"
}

extension MIMEType.Parameter.Key where Value == String {
    public static let boundary: Self = "boundary"
    public static let name: Self = "name"
    public static let fileName: Self = "filename"
}
