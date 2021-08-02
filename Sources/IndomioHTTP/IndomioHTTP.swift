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

/// Current IndomioNetwork version.
let LibraryVersion = "1.0.0"

public struct HTTPError: LocalizedError {
    
    /// HTTP Status Code if available.
    public let statusCode: HTTPStatusCode
    
    /// Cocoa related code.
    public var cocoaCode: Int?
    
    /// Long description of the error.
    public let error: Error?
    
    /// Category of the error.
    public let type: ErrorType
    
    /// Additional user info.
    public var userInfo: [String: Any]?
    
    // MARK: - Initialization
        
    public init(_ type: ErrorType,
                code: HTTPStatusCode = .none,
                error: Error? = nil,
                userInfo: [String: Any]? = nil,
                cocoaCode: Int? = nil) {
        self.type = type
        self.statusCode = code
        self.error = error
        self.userInfo = userInfo
        self.cocoaCode = cocoaCode
    }
    
    // MARK: - Public Properties
    
    public var errorDescription: String? {
        return error?.localizedDescription
    }
    
    /// Return `true` if error is related to a missing connectivity.
    public var isConnectivityError: Bool {
        cocoaCode == -1009
    }
    
    /// Return `true` if error is about a missing authorization.
    public var isNotAuthorized: Bool {
        statusCode == .unauthorized
    }
    
}

public extension HTTPError {
    enum ErrorType {
        case invalidURL(URLConvertible)
        case multipartInvalidFile(URL)
        case multipartFailedStringEncoding
        case multipartStreamReadFailed
        case jsonEncodingFailed
        case urlEncodingFailed
        case generic(Error)
        case network
        case connectionError
        case invalidResponse
        case failedBuildingURLRequest
    }
}
