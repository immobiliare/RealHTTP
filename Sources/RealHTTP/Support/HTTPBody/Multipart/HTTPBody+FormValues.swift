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

extension HTTPBody {
    
    /// Initialize a new body with a form values dictionary.
    ///
    /// - Parameter values: values.
    /// - Returns: HTTPBody
    public static func form(values: [String: String]) -> HTTPBody {
        .form(values: values.map { URLQueryItem(name: $0.key, value: $0.value) })
    }
    
    /// Initialize a new body with a form values as `URLQueryItem` array.
    ///
    /// - Parameter values: values.
    /// - Returns: HTTPBody
    public static func form(values: [URLQueryItem]) -> HTTPBody {
        let content = values.compactMap { item in
            guard let name = item.name.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
                  let value = item.value?.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
                      return nil
                  }
            return "\(name)=\(value)"
        }.joined(separator: "&")
        return .string(content, contentType: .application.wwwForm.appending(.characterSet, value: .utf8))
    }
    
}
