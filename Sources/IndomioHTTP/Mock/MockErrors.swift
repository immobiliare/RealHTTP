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

public enum MockErrors: Error, LocalizedError {
    case missingMock(String)
    case mockFailure(String)
    
    public var errorDescription: String? {
        switch self {
        case .missingMock(let url):
            return "Missing mock for url: \(url)"
        case .mockFailure(let url):
            return "Failed to mock url: \(url)"
        }
    }
    
}
