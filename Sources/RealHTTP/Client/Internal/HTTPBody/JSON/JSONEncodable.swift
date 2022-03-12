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

extension HTTPBody {
    
    /// This represent an `Encodable` conform object which can be transformed
    /// to a JSON string and sent over the network.
    public actor JSONEncodable: HTTPSerializableBody {
        
        // MARK: - Public Properties
        
        /// Encoder used to encode the JSON object.
        public var jsonEncoder: JSONEncoder
        
        /// Object to encode.
        public var object: Encodable {
            return _object.value
        }
        
        // MARK: - Private Properties
        
        /// Object to encode encapsulated with type-erasure.
        private var _object: AnyEncodable
        
        // MARK: - Initialization
        
        /// Initialize a new body container to encode the JSON.
        internal init<T: Encodable>(_ object: T, encoder: JSONEncoder = .init()) {
            self._object = AnyEncodable(object)
            self.jsonEncoder = encoder
        }
        
        /// Encode the data.
        ///
        /// - Returns: Data
        public func serializeData() async throws -> (data: Data, additionalHeaders: HTTPHeaders?) {
            let data = try jsonEncoder.encode(_object)
            return (data, .forData(data))
        }
        
    }
    
}

// MARK: - AnyEncodable

/// This is used only to encapsulate an Encodable object with type-erasure.
internal struct AnyEncodable : Encodable {
    
    /// Object to encapsulate.
    var value: Encodable
    
    // MARK: - Initialization
    
    init(_ value: Encodable) {
        self.value = value
    }
    
    // MARK: - Encodable Conformance
    
    func encode(to encoder: Encoder) throws {
        let container = encoder.singleValueContainer()
        try value.encode(to: container as! Encoder)
    }
    
}


