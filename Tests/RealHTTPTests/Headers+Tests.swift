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
import XCTest
@testable import RealHTTP

class HeadersTests: XCTestCase {
    
    private lazy var client: HTTPClient = {
        var configuration = URLSessionConfiguration.default

        // Set cookie policies.
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpCookieStorage = HTTPCookieStorage()
        configuration.httpShouldSetCookies = false
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpCookieStorage?.cookieAcceptPolicy = .always
        
        let client = HTTPClient(baseURL: nil, maxConcurrentOperations: nil, configuration: configuration)
        return client
    }()
    
    override class func setUp() {
        super.setUp()
        
        HTTPStubber.shared.enable()
        
        let echo = HTTPStubRequest().match(urlRegex: "*").stubEcho()
        HTTPStubber.shared.add(stub: echo)
    }
    
    override class func tearDown() {
        HTTPStubber.shared.removeAllStubs()
        HTTPStubber.shared.disable()
        super.tearDown()
    }
    
    /// The following tests evaluate headers passed in type-safe
    /// and not type-safe manner checking if the echo response is equal.
    func test_headersPresetsAndCustoms() async throws {
        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8080")!
            $0.method = .post
            $0.headers = HTTPHeaders(headers: [
                // Accept
                .accept("audio/*; q=0.2, audio/basic"),
                .acceptCharset("iso-8859-5, unicode-1-1;q=0.8"),
                .acceptLanguage("da, en-gb;q=0.8, en;q=0.7"),
                .acceptRanges("bytes"),
                .acceptEncoding("compress, gzip"),
                
                // Content
                .contentDisposition("inline"),
                .contentType(.aac),
                .contentLength("3495"),
                
                // Others
                .userAgent("CERN-LineMode/2.15 libwww/2.17b3"),
                .cacheControl(.onlyIfCached),
                
                // Custom Values
                .init(name: "X-Agent", value: "CustomValue"),
                .init(name: "X-API-Key", value: "abcdefgh123456789")
            ])
        }
        
        let result = try await req.fetch()
        XCTAssert(req.headers == result.httpResponse?.headers, "Headers received are different")
    }
    
    /// The following test check if custom headers are written and available correctly
    /// inside the request instance.
    func test_headers_authorizationHeaders() async throws {
        
        let authsList: [(header: HTTPHeaders.Element, valueToCheck: String)] = [
            // Custom Authorization Scheme
            (.auth("MyScheme ABC-DFG-HI"),
             "MyScheme ABC-DFG-HI"),
            // Basic Authorization Scheme
            (.authBasic(username: "myusername", password: "1234abc"),
             "Basic " + "myusername:1234abc".data!.base64EncodedString()),
            // Bearer Token
            (.authBearerToken("xvz1evFS4wEEPTGEFPHBog:L8qq9PZyRg6ieKGEKhZolGC0vJWLw8iEJ88DRdyOg"),
            "Bearer xvz1evFS4wEEPTGEFPHBog:L8qq9PZyRg6ieKGEKhZolGC0vJWLw8iEJ88DRdyOg"),
            // OAuth
            (.authOAuth("hY_9.B5f-4.1BfE"), "OAuth hY_9.B5f-4.1BfE"),
            // X-API-Key
            (.xAPIKey("abcdefgh123456789"), "X-API-Key: abcdefgh123456789")
        ]
        
        for auth in authsList {
            let req = HTTPRequest {
                $0.url = URL(string: "http://127.0.0.1:8080")!
                $0.headers = HTTPHeaders(headers: [
                    auth.header
                ])
            }
            
            let result = try await req.fetch()
            XCTAssert(req.headers == result.httpResponse?.headers, "Headers received are different")
        }
    }
    
    /// Test the presence of the default headers into the call.
    func test_headers_defaultHeaders() async throws {
        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8080")!
            $0.headers = HTTPHeaders.default
        }
        
        let result = try await req.fetch()
        XCTAssertNoThrow(try checkHeaders([.acceptEncoding, .acceptLanguage, .userAgent], in: result))
    }
    
    /// Test the default encoding value if present and it's correct.
    func test_headers_validateDefaultAcceptEncoding() async throws {
        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8080")!
            $0.headers = HTTPHeaders.default
        }
        
        let result = try await req.fetch()
        XCTAssertNoThrow(try checkHeaders([.acceptEncoding], in: result))
        
        let expectedEncoding = ["br", "gzip", "deflate"].encodedWithQuality()
        XCTAssert(result.httpResponse?.headers[.acceptEncoding] == expectedEncoding, "Default accept encoding is not valid")
    }
    
    // MARK: - Helper Functions
    
    private func checkHeaders(_ keys: [HTTPHeaders.Element.Name], in response: HTTPResponse, strict: Bool = false) throws {
        let responseHeaders = response.httpResponse?.headers.keys.map({ $0.rawValue }).sorted()
        let checkHeaders = keys.map({ $0.rawValue }).sorted()

        guard strict else {
            for header in checkHeaders {
                if responseHeaders?.contains(header) ?? false == false {
                    throw TestError("Header '\(header)' is not present in response")
                }
            }
            return
        }
        
        if checkHeaders != responseHeaders {
            throw TestError("Headers are not the same you require")
        }
    }
    
}

public struct TestError: Error, ExpressibleByStringLiteral, ExpressibleByStringInterpolation, LocalizedError {
    let message: String
    
    public init(stringLiteral value: StringLiteralType) {
        self.message = value
    }
    
    public var errorDescription: String? {
        message
    }
    
}
