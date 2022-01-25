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

extension HTTPRequest {
    
    /// Return the cURL representation of the request when loaded
    /// inside a specific client.
    ///
    /// - Parameter client: client where the request should run.
    /// - Returns: String
    public func cURLDescription(whenIn client: HTTPClient?) -> String {
        guard let client = client,
              let request = try? urlRequest(inClient: client),
              let _ = request.url,
              let method = request.httpMethod else {
            return "$ curl command could not be created"
        }
        
        var components = [
            "$ curl -v"
        ]

        components += "-X \(method)"

        addCredentials(for: request, whenIn: client, into: &components)
        addSetCookies(for: request, whenIn: client, into: &components)
        addHeaders(for: request, whenIn: client, into: &components)
        addBody(for: request, whenIn: client, into: &components)
        
        return components.joined(separator: " \\\n\t")
    }
    
    // MARK: - Private Fucntions
    
    // Add credentials in cURL representation of a request.
    ///
    /// - Parameters:
    ///   - request: request.
    ///   - client: where the request is running in.
    ///   - components: components array.
    private func addCredentials(for request: URLRequest, whenIn client: HTTPClient, into components: inout [String]) {
        guard let credentialStorage = client.session.configuration.urlCredentialStorage,
              let url = request.url,
              let host = url.host else {
            return
        }
        
        let protectionSpace = URLProtectionSpace(host: host,
                                                 port: url.port ?? 0,
                                                 protocol: url.scheme,
                                                 realm: host,
                                                 authenticationMethod: NSURLAuthenticationMethodHTTPBasic)

        if let credentials = credentialStorage.credentials(for: protectionSpace)?.values {
            for credential in credentials {
                guard let user = credential.user, let password = credential.password else { continue }
                components.append("-u \(user):\(password)")
            }
        }
    }
    
    // Add cookies components in cURL representation of a request.
    ///
    /// - Parameters:
    ///   - request: request.
    ///   - client: where the request is running in.
    ///   - components: components array.
    private func addSetCookies(for request: URLRequest, whenIn client: HTTPClient, into components: inout [String]) {
        let configuration = client.session.configuration
        guard configuration.httpShouldSetCookies,
              let url = request.url else {
            return
        }
        
        if
            let cookieStorage = configuration.httpCookieStorage,
            let cookies = cookieStorage.cookies(for: url), !cookies.isEmpty {
            let allCookies = cookies.map { "\($0.name)=\($0.value)" }.joined(separator: ";")

            components.append("-b \"\(allCookies)\"")
        }
        
    }
    
    // Add headers components in cURL representation of a request.
    ///
    /// - Parameters:
    ///   - request: request.
    ///   - client: where the request is running in.
    ///   - components: components array.
    private func addHeaders(for request: URLRequest, whenIn client: HTTPClient, into components: inout [String]) {
        let configuration = client.session.configuration
        var headers = HTTPHeaders()
        
        for header in configuration.headers where header.name != "Cookie" {
            headers[header.name] = header.value
        }
        
        for header in request.headers where header.name != "Cookie" {
            headers[header.name] = header.value
        }
        
        for header in headers {
            let escapedValue = header.value.replacingOccurrences(of: "\"", with: "\\\"")
            components.append("-H \"\(header.name.rawValue): \(escapedValue)\"")
        }
    }
    
    /// Add body components in cURL representation of a request.
    ///
    /// - Parameters:
    ///   - request: request.
    ///   - client: where the request is running in.
    ///   - components: components array.
    private func addBody(for request: URLRequest, whenIn client: HTTPClient, into components: inout [String]) {
        if let httpBodyData = request.httpBody {
            let httpBody = String(decoding: httpBodyData, as: UTF8.self)
            var escapedBody = httpBody.replacingOccurrences(of: "\\\"", with: "\\\\\"")
            escapedBody = escapedBody.replacingOccurrences(of: "\"", with: "\\\"")

            components.append("-d \"\(escapedBody)\"")
        }

        components.append("\"\(request.url!.absoluteString)\"")
    }
    
}
