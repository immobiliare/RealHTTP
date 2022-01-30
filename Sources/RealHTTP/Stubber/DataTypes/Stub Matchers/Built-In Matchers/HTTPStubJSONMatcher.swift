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

/// HTTPStubJSONMatcher allows you to create a particular matcher for a json body
/// contained into the request.
/// For example you can use your Codable structure to match a stubbed request with particular values.
///
/// Example: Suppose you have an struct with user data:
/// ```swift
/// public struct User: Codable, Hashable {
///   var userID: Int
///   var fullName: String
/// }
/// ```
/// Now you want to match a request with this oject into the body with particular values. You need to add a new json matcher as follows:
///
/// ```swift
/// var stubUserObj = HTTPStubRequest()
///                   .addJSONMatch(User(userID: 34, fullName: "Mark"))
/// ```
///
/// Stub is triggered for this particular object value.
public class HTTPStubJSONMatcher<T: Decodable & Hashable>: HTTPStubMatcher {
    
    // MARK: - Private Properties
    
    private let decoder: JSONDecoder
    private let object: T
    
    // MARK: - Initialization
    
    public init(matchObject object: T) {
        self.decoder = JSONDecoder()
        self.object = object
    }
    
    // MARK: - Conformance
    
    public func matches(request: URLRequest, for source: HTTPMatcherSource) -> Bool {
        guard let data = request.body,
              let decodedObject = try? self.decoder.decode(T.self, from: data) else {
            return false
        }
        
        // check if both the decoded object is equal to our passed object.
        return object == decodedObject
    }
    
}
