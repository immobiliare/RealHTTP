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

extension HTTPBody {
    
    /// Initialize a new multipart form data body.
    ///
    /// - Parameters:
    ///   - boundary: boundary to set. `nil` to auto-assign value.
    ///   - configure: configuration callback to fillout the form.
    /// - Returns: HTTPBody
    public static func multipart(boundary: String? = nil,
                                 _ configure: ((inout MultipartForm) throws -> Void)) rethrows -> HTTPBody {
        var formData = MultipartForm(boundary: boundary)
        try configure(&formData)
        return HTTPBody.empty
    }
    
    
}
