//
//  RealHTTP
//  Lightweight Async/Await Network Layer/Stubber for Swift
//
//  Created & Maintained by Mobile Platforms Team @ ImmobiliareLabs.it
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Created by: Daniele Margutti <hello@danielemargutti.com>

//  CONTRIBUTORS:
//  Thank you to all the contributors who made this project better:
//  <https://github.com/immobiliare/RealHTTP/graphs/contributors>
//
//  Copyright ©2022 Immobiliare.it SpA.
//  Licensed under MIT License.
//

import Foundation

// MARK: - HTTPRequestPriority

/// Allows you to define the priority of request.
/// It acts different based upon the HTTPClient instance used.
///
/// For a simple `HTTPClient` it acts as an hint to the receiver host.
/// In this case it's a wrapper to HTTP/2 priority frames / dependency weighting
/// See:
/// <https://developer.apple.com/forums/thread/48371>
/// <http://www.ietf.org/rfc/rfc7540.txt>)
/// 
public enum HTTPRequestPriority: String {
    case veryLow
    case low
    case normal
    case high
    case veryHigh
    
    // MARK: - Internal Properties
    
    internal var urlTaskPriority: Float {
        switch self {
        case .veryLow:  return 0.1
        case .low:      return 0.3
        case .normal:   return 0.5
        case .high:     return 0.7
        case .veryHigh: return 1.0
        }
    }
    
    public var description: String {
        rawValue
    }
    
}
