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


// MARK: - ImageFormat

extension HTTPStubRequest {
    
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
