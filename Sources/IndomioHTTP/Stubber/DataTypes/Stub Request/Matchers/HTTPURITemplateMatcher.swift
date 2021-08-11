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

/// This is a matcher wich allows to use URI templates (as defined by RFC)
/// to match a request's url.
/// For example you can use the following URI template:
/// "/kylef/Mockingjay"
///
/// to match the following URLs:
///
/// - https://github.com/kylef/WebLinking.swift
/// - https://github.com/kylef/{repository}
/// - /kylef/{repository}
/// - /kylef/URITemplate.swift
///
/// Original implementation of the URITemplate (see URITemplate.swift) was
/// made by Kyle Fuller <https://github.com/kylef>.
public class HTTPURITemplateMatcher: HTTPStubMatcherProtocol {
    
    // MARK: - Private Properties
    
    /// Compiled template.
    private var template: URITemplate
    
    // MARK: - Initialization
    
    /// Initialize a new URI matcher.
    ///
    /// - Parameter uriString: URI template string.
    public init(URI uriString: String) {
        self.template = URITemplate(template: uriString)
    }
    
    // MARK: - Conformance
    
    public func matches(request: URLRequest, forStub stub: HTTPStubRequest) -> Bool {
        if let URLString = request.url?.absoluteString {
            if template.extract(URLString) != nil {
                return true
            }
        }
        
        if let path = request.url?.path {
            if template.extract(path) != nil {
                return true
            }
        }
        
        return false
    }
    
}
