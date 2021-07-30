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

// MARK: - Boundary

extension MultipartFormData {
    
    /// Boundary object identify the sequence used to separate components in a multipart form data.
    internal struct Boundary: ExpressibleByStringLiteral {
        
        /// Identifier of the boundary.
        public let id: String
        
        /// CR+LF characters sequence to separate components.
        public static let crlf = "\r\n"
        
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
        
        /// Return the boundary string for a part of the multipart form.
        ///
        /// - Parameter kind: kind of boundary to get.
        /// - Returns: String
        internal func boundaryStringFor(_ kind: Kind) -> String {
            switch kind {
            case .start:
                return "--\(id)\(Boundary.crlf)"
            case .encapsulated:
                return "\(Boundary.crlf)--\(id)\(Boundary.crlf)"
            case .end:
                return "\(Boundary.crlf)--\(id)--\(Boundary.crlf)"
            }
        }
        
        // MARK: - Private Functions
        
        fileprivate static func generate() -> String {
            let firstPart = UInt32.random(in: UInt32.min...UInt32.max)
            let secondPart = UInt32.random(in: UInt32.min...UInt32.max)
            return String(format: "indomiohttp.boundary.%08x%08x", firstPart, secondPart)
        }
        
    }
    
}

// MARK: - Kind

extension MultipartFormData.Boundary {
    
    /// Type of boundary.
    /// - `start`: initial sequence of the form
    /// - `encapsulated`: single item.
    /// - `end`: cosing sequence of the form
    enum Kind {
        case start
        case encapsulated
        case end
    }
    
}
