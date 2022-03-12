//
//  File.swift
//  
//
//  Created by Daniele Margutti on 22/02/22.
//

import Foundation

/// The following protocol is used to transform the `HTTPResponse` object
/// before sending the final response from the client.
/// You can use it to perform your own logic (ie. for example you have a `data`
/// node with the object along with some other json nodes and you want to
/// just pass the content of `data` as root object of the response).
public protocol HTTPResponseTransform {
    
    /// Perform transformation of the object itself.
    ///
    /// - Returns: `HTTPResponse`
    func transform(response: HTTPResponse, ofRequest request: HTTPRequest) throws -> HTTPResponse
    
}

// MARK: - HTTPResponseTransformerBlock

/// Concrete implementation of the `HTTPResponseTransformer` which uses callbacks.
public struct HTTPResponseTransformer: HTTPResponseTransform {
    
    public typealias Callback = ((_ response: HTTPResponse, _ request: HTTPRequest) throws -> HTTPResponse)
    
    // MARK: - Private Properties
    
    /// Callback function.
    private var callback: Callback
    
    // MARK: - Initialization
    
    /// Initialize a new callback.
    ///
    /// - Parameter callback: callback.
    public init(_ callback: @escaping Callback) {
        self.callback = callback
    }
    
    public func transform(response: HTTPResponse, ofRequest request: HTTPRequest) throws -> HTTPResponse {
        try callback(response, request)
    }
    
}
