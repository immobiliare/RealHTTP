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

public enum IndomioHTTPError: Error {
    case invalidURL(URLConvertible)
    case multipartInvalidFile(URL)
    case multipartFailedStringEncoding
    case multipartStreamReadFailed(Error)
}
