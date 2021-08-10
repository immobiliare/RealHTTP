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

public class HTTPStubURLProtocol: URLProtocol {
    
    /// This class support only certain common type of schemes.
    private static let supportedSchemes = ["http", "https"]
    
    // MARK: - Overrides
    
    /// The following call is called when a new request is about to being executed.
    /// The following stub subclass supports only certain schemes, http and https so we
    /// want to reply affermative (and therefore manage it) only for these schemes.
    /// When false other registered protocol classes are queryed to respond.
    ///
    /// - Parameter request: request to validate.
    /// - Returns: Bool
    public override class func canInit(with request: URLRequest) -> Bool {
        guard let scheme = request.url?.scheme,
              Self.supportedSchemes.contains(scheme) else {
            return false
        }
        
        return true
    }
    
    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }
    
    public override class func requestIsCacheEquivalent(_ a: URLRequest, to b: URLRequest) -> Bool {
        false
    }
    
    public override func startLoading() {
        var request = self.request
        
        // Get the cookie storage that applies to this request.
        var cookieStorage = HTTPCookieStorage.shared
       /* if let session = task?.value(forKey: "session") as? URLSession,
           let configurationCookieStorage = session.configuration.httpCookieStorage {
            cookieStorage = configurationCookieStorage
        }*/
        
        // Get the cookies that apply to this URL and add them to the request headers.
        if let url = request.url, let cookies = cookieStorage.cookies(for: url) {
            if request.allHTTPHeaderFields == nil {
                request.allHTTPHeaderFields = [String: String]()
            }
            request.allHTTPHeaderFields!.merge(HTTPCookie.requestHeaderFields(with: cookies)) { (current, _) in
                current
            }
        }
        
        // Find the stubbed response for this request.
        guard  let httpMethod = request.method,
               let stubResponse = HTTPStubber.shared.suitableStubForRequest(request)?.responses[httpMethod],
               let url = request.url else {
            // If not found we throw an error
            client?.urlProtocol(self, didFailWithError: HTTPStubberErrors.matchStubNotFound(request))
            return
        }
        
        let headers = stubResponse.headers?.asDictionary ?? [:]
        let cookiesToSet = HTTPCookie.cookies(withResponseHeaderFields: headers, for: url)
        cookieStorage.setCookies(cookiesToSet, for: url, mainDocumentURL: url)

        if let failureError = stubResponse.failError { // request should fail with given error
            client?.urlProtocol(self, didFailWithError: failureError)
            return
        }
        
        let statusCode = stubResponse.statusCode
        let response = HTTPURLResponse(url: url,
                                       statusCode: statusCode.rawValue,
                                       httpVersion: nil,
                                       headerFields: headers)
        
        // Handle redirects
        let isRedirect =
            statusCode.responseType == .redirection &&
            (statusCode != .notModified && statusCode != .useProxy)
        
        if isRedirect {
            guard let location = stubResponse.headers?["Location"],
                  let url = URL(string: location),
                  let cookies = cookieStorage.cookies(for: url) else {
                return
            }
            
            // Includes redirection call to client.
            var redirect = URLRequest(url: url)
            redirect.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
            client?.urlProtocol(self, wasRedirectedTo: redirect, redirectResponse: response!)
        }
        
        // Send response
        client?.urlProtocol(self, didReceive: response!, cacheStoragePolicy: .notAllowed)
        if let data = stubResponse.body?.data {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }
    
    public override func stopLoading() {
        
    }
    
    
}
