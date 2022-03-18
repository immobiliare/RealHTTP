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

/// This class is used to provide a dynamic `HTTPStubResponse` based upon the request
/// received from the matcher.
public struct HTTPDynamicStubResponse: HTTPStubResponseProvider {
    public typealias DataCallbackProvider = ((URLRequest, HTTPStubRequest) -> HTTPStubResponse)
    
    // MARK: - Public Properties
    
    /// Callback which provide the response for stub.
    public let callback: DataCallbackProvider
    
    // MARK: - Initialization
    
    /// Initialize a new dynamic stub response provider.
    ///
    /// - Parameter callback: callback provider.
    public init(_ callback: @escaping DataCallbackProvider) {
        self.callback = callback
    }
    
    // MARK: - Protocol Conformance
    
    public func response(forURLRequest urlRequest: URLRequest, matchedStub stubRequest: HTTPStubRequest) -> HTTPStubResponse? {
        callback(urlRequest, stubRequest)
    }
    
}
