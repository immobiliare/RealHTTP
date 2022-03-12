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
    
    /// Encapsulate an object which can be serialized using
    /// the system's `JSONSerialization` class.
    public class JSONSerializable: HTTPSerializableBody {
        
        // MARK: - Public Properties
        
        /// Object to encode.
        public var object: Any
        
        /// Options for serialization.
        public var options: JSONSerialization.WritingOptions
        
        // MARK: - Initialization
        
        /// Initialize a new body with given object to serialize and options.
        internal init(_ object: Any, options: JSONSerialization.WritingOptions = []) {
            self.object = object
            self.options = options
        }
        
        // MARK: - HTTPSerializableBody Conformance
        
        public func serializeData() async throws -> (data: Data, additionalHeaders: HTTPHeaders?) {
            let data = try JSONSerialization.data(withJSONObject: object, options: options)
            return (data, .forData(data))
        }
        
    }
    
}
