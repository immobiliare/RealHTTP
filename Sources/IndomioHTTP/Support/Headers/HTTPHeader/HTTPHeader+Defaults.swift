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

// MARK: - HTTPHeader Defaults Initialization

extension HTTPHeader {
    
    /// Create the default `Accept-Encoding` header.
    public static let defaultAcceptEncoding: HTTPHeader = {
        .acceptEncoding(["br", "gzip", "deflate"].encodedWithQuality())
    }()
    
    /// Create the default `Accept-Language` header generated
    /// from the current system's locale settings.
    public static let defaultAcceptLanguage: HTTPHeader = {
        let value = Locale.preferredLanguages.prefix(6).encodedWithQuality()
        return .acceptLanguage(value)
    }()
    
    /// Create the default `User-Agent` header.
    /// See <https://tools.ietf.org/html/rfc7231#section-5.5.3>.
    public static let defaultUserAgent: HTTPHeader = {
        let libraryVersion = "IndomioNetwork/\(LibraryVersion)"
        let mainBundle = Bundle.main
        let value = "\(mainBundle.executableName)/\(mainBundle.appVersion) (\(mainBundle.bundleID); build:\(mainBundle.appBuild); \(mainBundle.osNameIdentifier)) \(libraryVersion)"
        return .userAgent(value)
    }()
    
}


// MARK: - Extensions

fileprivate extension Collection where Element == String {
    
    /// See https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html.
    ///
    /// - Returns: String
    func encodedWithQuality() -> String {
        enumerated().map { index, encoding in
            let quality = 1.0 - (Double(index) * 0.1)
            return "\(encoding);q=\(quality)"
        }.joined(separator: ", ")
    }
    
}
