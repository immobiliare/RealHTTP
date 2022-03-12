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

// MARK: - cURL for HTTPRequest

extension HTTPRequest {
    
    /// Return the cURL representation of the origin request which
    /// originate this response.
    ///
    /// NOTE:
    ///
    /// Parent client must be exists in order to get valid results.
    /// This is an asynchronous call because it needs to serialize data and
    /// it's asynchronous operation.
    /// You can use the `HTTPResponse`'s `curlDescription()` to have a sync
    /// response for an executed request.
    ///
    /// - Returns: String
    func cURLDescription(whenIn client: HTTPClient?) async throws -> String {
        let request = try await urlRequest(inClient: client)
        return cURLHelper.cURLDescription(request: request, client: client)
    }
    
}

// MARK: - cURL for HTTPResponse

extension HTTPResponse {
    
    /// Return the cURL description for origin request who generated this response.
    ///
    /// - Returns: String
    func cURLDescription() -> String {
        cURLHelper.cURLDescription(request: request?.sessionTask?.originalRequest, client: request?.client)
    }
    
}

// MARK: - cURLHelper

/// Contains the relevant information to print cURL description for requests and responses.
public struct cURLHelper {
    
    fileprivate static func cURLDescription(request: URLRequest?, client: HTTPClient?) -> String {
        guard let client = client,
              let request = request,
              let _ = request.url else {
                  return "$ curl command could not be created"
              }
        
        var components = [
            "$ curl -v"
        ]
        
        components += "-X \(request.httpMethod ?? "")"
        
        cURLHelper.addCredentials(for: request, whenIn: client, into: &components)
        cURLHelper.addSetCookies(for: request, whenIn: client, into: &components)
        cURLHelper.addHeaders(for: request, whenIn: client, into: &components)
        cURLHelper.addBody(for: request, whenIn: client, into: &components)
        
        return components.joined(separator: " \\\n\t")
    }
    
    // MARK: - Private Fucntions
    
    // Add credentials in cURL representation of a request.
    ///
    /// - Parameters:
    ///   - request: request.
    ///   - client: where the request is running in.
    ///   - components: components array.
    private static func addCredentials(for request: URLRequest, whenIn client: HTTPClient, into components: inout [String]) {
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
    private static func addSetCookies(for request: URLRequest, whenIn client: HTTPClient, into components: inout [String]) {
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
    private static func addHeaders(for request: URLRequest, whenIn client: HTTPClient, into components: inout [String]) {
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
    private static func addBody(for request: URLRequest, whenIn client: HTTPClient, into components: inout [String]) {
        if let httpBodyData = request.httpBody {
            let httpBody = String(decoding: httpBodyData, as: UTF8.self)
            var escapedBody = httpBody.replacingOccurrences(of: "\\\"", with: "\\\\\"")
            escapedBody = escapedBody.replacingOccurrences(of: "\"", with: "\\\"")
            
            components.append("-d \"\(escapedBody)\"")
        }
        
        components.append("\"\(request.url!.absoluteString)\"")
    }
    
}
