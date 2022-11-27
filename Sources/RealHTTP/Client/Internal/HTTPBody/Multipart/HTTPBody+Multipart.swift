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
        return HTTPBody(content: formData)
    }
    
    /// Create a multipart form with given object.
    ///
    /// - Parameter form: form object
    public static func multipart(_ form: MultipartForm) -> HTTPBody {
        HTTPBody(content: form)
    }
    
}

extension HTTPBody {
    
    /// Return content as `MultipartForm`.
    public var asMultipartForm: MultipartForm? {
        content as? MultipartForm
    }
    
}
