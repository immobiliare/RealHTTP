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

// MARK: - MockRequestDataConvertible

public protocol MockRequestDataConvertible {
    var data: Data? { get }
}

extension String: MockRequestDataConvertible {
    public var data: Data? { self.data(using: .utf8) }
}

extension Data: MockRequestDataConvertible {
    public var data: Data? { self }
}

extension MockRequest {
    
    public struct MatchingOptions: OptionSet {
        public let rawValue: Int

        static let ignoreQueryParams = MatchingOptions(rawValue: 1 << 0)
        static let all: MatchingOptions = [.ignoreQueryParams]
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    
}

// MARK: - MockResponseDataType

extension MockRequest {
    
    public enum MockResponseDataType {
        case json
        case html
        case image(ImageFormat)
        case pdf
        case mp4
        case zip
        case other(header: String)
        
        internal var headerValue: String {
            switch self {
            case .json:                 return "application/json; charset=utf-8"
            case .html:                 return "text/html; charset=utf-8"
            case .image(let format):    return "image/\(format.value)"
            case .pdf:                  return "application/pdf"
            case .mp4:                  return "video/mp4"
            case .zip:                  return "application/zip"
            case .other(let h):         return h
            }
        }
    }
}

// MARK: - ImageFormat

extension MockRequest {
    
    public enum ImageFormat {
        case jpg
        case png
        case gif
        case other(String)
        
        internal var value: String {
            switch self {
            case .jpg: return "jpg"
            case .png: return "png"
            case .gif: return "gif"
            case .other(let v): return v
            }
        }
    }
    
}
