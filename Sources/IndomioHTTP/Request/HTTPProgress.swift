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

public struct HTTPProgress {
    
    /// Progress information object.
    public let info: Progress
    
    /// Percentage of the transfer.
    public let percentage: Float
    
    /// Kind of transfer.
    public internal(set) var kind: Kind = .download
    
    /// Indicates the position of the resumed offset for download.
    public internal(set) var resumedOffset: Int64? = nil

}

public extension HTTPProgress {
    
    enum Kind {
        case upload
        case download
    }
    
}
