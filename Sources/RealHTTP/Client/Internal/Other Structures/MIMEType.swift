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

/// A list of known MIME Types
public enum MIMEType: ExpressibleByStringLiteral {
    case wwwFormUtf8
    case jsonUtf8
    case json
    case pdf
    case zip
    case gzip

    // Text
    case html
    case csv
    case xml
    case javascript
    case textPlain

    // Font
    case otf
    case ttf
    case woff
    case woff2

    // Image
    case jpg
    case gif
    case png
    case webp
    
    case custom(String)
    
    // MARK: - Public Properties
    
    public var rawValue: String {
        switch self {
        case .wwwFormUtf8:  return "application/x-www-form-urlencoded; charset=utf-8"
        case .jsonUtf8:     return "application/json; charset=utf-8"
        case .json:         return "application/json"
        case .pdf:          return "application/pdf"
        case .zip:          return "application/zip"
        case .gzip:         return "application/gzip"
        case .html:         return "text/html"
        case .csv:          return "text/csv"
        case .xml:          return "text/xml"
        case .javascript:   return "text/javascript"
        case .textPlain:    return "text/plain"
        case .otf:          return "font/otf"
        case .ttf:          return "font/ttf"
        case .woff:         return "font/woff"
        case .woff2:        return "font/woff2"
        case .jpg:          return "image/jpeg"
        case .gif:          return "image/gif"
        case .png:          return "image/png"
        case .webp:         return "image/webp"
        case .custom(let v):return v
        }
    }
    
    // MARK: - Initialization with literal
    
    public init(stringLiteral value: StringLiteralType) {
        self = .custom(value)
    }
    
}
