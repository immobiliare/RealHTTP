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

// MARK: - Boundary

extension MultipartFormData {
    
    /// Boundary object identify the sequence used to separate components in a multipart form data.
    internal struct Boundary: ExpressibleByStringLiteral {
        
        /// Identifier of the boundary.
        public let id: String
        
        /// CR+LF characters sequence to separate components.
        public static let crlf = "\r\n"
        public static let crlfData = Boundary.crlf.data(using: .utf8)!
        
        // MARK: - Internal Properties
        
        internal var delimiter: String {
            "--" + id
        }
        
        internal var distinguishedDelimiter: String {
            self.delimiter + "--"
        }
        
        internal var delimiterData: Data {
            self.delimiter.data(using: .utf8)!
        }
        
        internal var distinguishedDelimiterData: Data {
            self.distinguishedDelimiter.data(using: .utf8)!
        }

        // MARK: - Initialization
        
        /// Initialize a new boundary identifier.
        ///
        /// - Parameter id: string with the identifier; ignore to generate the id automatically.
        public init(_ id: String? = nil) {
            self.id = id ?? Boundary.generate()
        }
        
        /// Initialize a new boundary object from a string.
        ///
        /// - Parameter value: string with the identifier.
        public init(stringLiteral value: String) {
            self = Boundary(value)
        }
        
        // MARK: - Private Functions
        
        fileprivate static func generate() -> String {
            let firstPart = UInt32.random(in: UInt32.min...UInt32.max)
            let secondPart = UInt32.random(in: UInt32.min...UInt32.max)
            return String(format: "indomiohttp.boundary.%08x%08x", firstPart, secondPart)
        }
        
    }
    
}
