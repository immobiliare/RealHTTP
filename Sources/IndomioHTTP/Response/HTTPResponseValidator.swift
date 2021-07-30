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

// MARK: - HTTPResponseValidator

public typealias HTTPResponse = (response: URLResponse?, data: Data?, error: Error?)

public protocol HTTPResponseValidator {
    
    /// Validate the reponse of an HTTP operation and throw an exception if something is wrong.
    ///
    /// - Parameters:
    ///   - response: URL response.
    ///   - data: data received.
    ///   - error: error received.
    func validate(response: HTTPResponse) -> Error?
    
}

// MARK: - HTTPStandardValidator

public struct HTTPStandardValidator: HTTPResponseValidator {
    
    // MARK: - Public Properties
    
    /// If `true` empty responses are tracked as valid responses if status code it's not an error.
    public var allowsEmptyResponses: Bool = true
    
    // MARK: - Validation
    
    public func validate(response: HTTPResponse) -> Error? {
        HTTPError.fromHTTPResponse(response)
    }
    
}

// MARK: - HTTPError (URLResponse)

extension HTTPError {
    
    /// Parse the response of an HTTP operation and return `nil` if no error has found,
    /// a valid `HTTPError` if call has failed.
    ///
    /// - Parameter httpResponse: response from http layer.
    /// - Returns: HTTPError?
    public static func fromHTTPResponse(_ httpResponse: HTTPResponse) -> HTTPError? {
        // If HTTP is an error or an error has received we can create the error object
        let httpCode = HTTPStatusCode(URLResponse: httpResponse.response) ?? .none
        let isError = (httpResponse.error != nil || httpCode.responseType != .success)
        let cocoaErrorCode = (httpResponse.error as NSError?)?.code
        let userInfo = (httpResponse.error as NSError?)?.userInfo

        guard isError else {
            return nil
        }
        
        return HTTPError(.network,
                         code: httpCode,
                         error: httpResponse.error,
                         userInfo: userInfo,
                         cocoaCode: cocoaErrorCode)
    }
    
}
