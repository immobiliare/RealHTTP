//
//  RealHTTP
//
//  Created by the Mobile Team @ ImmobiliareLabs
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Copyright ©2021 Immobiliare.it SpA. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

public enum RealHTTP {
    
    /// Current RealHTTP version.
    static let sdkVersion = "1.0.0"
    
    /// Identifier of the agent string.
    static let agentIdentifier = "realhttp"
    
}

// MARK: - Global Fetch

extension RealHTTP {
    
    /// Fetch the request with the default client.
    public static func fetch(_ request: HTTPRequest) async throws -> HTTPResponse {
        try await HTTPClient.shared.fetch(request)
    }
    
}
