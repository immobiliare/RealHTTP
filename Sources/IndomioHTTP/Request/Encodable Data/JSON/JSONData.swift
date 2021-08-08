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

// MARK: - JSONData

/// Allows to create a JSON representation of the parameters object,
/// which is set as the body of the request.
/// The `Content-Type` HTTP header field of an encoded request is set to `application/json`.
open class JSONData: HTTPRequestEncodableData {
    
    // MARK: - Private Properties

    /// The options for writing the parameters as JSON data.
    private let options: JSONSerialization.WritingOptions
        
    /// Parameters to encode.
    private var data: Any
    
    // MARK: - Initialization
    
    public init(_ data: Any, options: JSONSerialization.WritingOptions = []) {
        self.data = data
        self.options = options
    }
    
    // MARK: - Encoding
    
    public func encodeParametersIn(request: inout URLRequest) throws {
        if request.headers[.contentType] == nil {
            request.headers[.contentType] = HTTPContentType.json.rawValue
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: data, options: options)
        } catch {
            throw HTTPError(.jsonEncodingFailed, error: error)
        }
    }
    
}

// MARK: - EncodableJSON

/// Allows to create a JSON representation of the parameters `Encodable` conform object,
/// which is set as the body of the request.
/// The `Content-Type` HTTP header field of an encoded request is set to `application/json`.
open class EncodableJSON<Object: Encodable>: HTTPRequestEncodableData {
    
    /// Object to convert.
    private var object: Object
    
    /// Encoder to use.
    private var encoder: JSONEncoder
    
    /// Return the default encoder with sorted keys option.
    ///
    /// - Returns: JSONEncoder
    private static func defaultEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
    
    // MARK: - Initialization
    
    /// Initialize a new `Encodable` object formatter.
    ///
    /// - Parameters:
    ///   - encoder: encoder to use, pass `nil` to use the default one.
    ///   - object: object to convert.
    public init(_ encoder: JSONEncoder?, object: Object) {
        self.object = object
        self.encoder = encoder ?? EncodableJSON.defaultEncoder()
    }
    
    // MARK: - Encoding
    
    public func encodeParametersIn(request: inout URLRequest) throws {
        if request.headers[.contentType] == nil {
            request.headers[.contentType] = HTTPContentType.json.rawValue
        }
        
        request.httpBody = try encoder.encode(object)
    }
    
}
