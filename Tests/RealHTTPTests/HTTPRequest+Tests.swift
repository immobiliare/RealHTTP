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
import Combine
@testable import RealHTTP

class HTTPRequest_Tests: XCTestCase {
    
    private var observerBag = Set<AnyCancellable>()
    
    private lazy var client: HTTPClient = {
        var configuration = URLSessionConfiguration.default

        // Set cookie policies.
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpCookieStorage = HTTPCookieStorage()
        configuration.httpShouldSetCookies = false
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpCookieStorage?.cookieAcceptPolicy = .always
        
        let client = HTTPClient(baseURL: URL(string: "https://api.github.com")!,
                                maxConcurrentOperations: nil,
                                configuration: configuration)
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
    
    // MARK: - URL Composition Tests
    
    /// We tests how replacing the `url` property the final executed url does
    /// not contains the `baseURL` of the destination `HTTPClient` instance.
    func testRequest_fullURL() throws {
        let fullURL = URL(string: "http://127.0.0.1:8080")!
        let req = HTTPRequest {
            $0.url = fullURL
        }
        
        let urlRequest = try req.urlRequest(inClient: client)
        XCTAssert(urlRequest.url == fullURL, "We expect a full URL to replace the baseURL, we got '\(urlRequest.url?.absoluteString ?? "")'")
    }
    
    /// Using an IP it should still works returning the full URL and ignoring the client's base url.
    func testRequest_fullURL_2() throws {
        let fullURL = URL(string: "http://127.0.0.1:8080")!
        let req = HTTPRequest {
            $0.url = fullURL
        }
        
        let urlRequest = try req.urlRequest(inClient: client)
        XCTAssert(urlRequest.url == fullURL, "We expect a full URL, we got '\(urlRequest.url?.absoluteString ?? "")'")
    }
    
    /// If we specify just the path of an URL the final URL must be the
    /// URL of the request composed with the destination client's baseURL.
    func testRequest_composedURL() throws {
        let req = HTTPRequest {
            $0.path = "user"
        }
        
        let urlRequest = try req.urlRequest(inClient: client)
        let expectedURL = URL(string: "\(client.baseURL!.absoluteString)\(req.path)")
        XCTAssert(urlRequest.url == expectedURL, "We expect composed URL, we got: '\(urlRequest.url?.absoluteString ?? "")'")
    }
    
    /// This test verify the query parameters you can add to the url.
    func testRequest_queryParameters() throws {
        let queryParams = [
            ("page", "1"),
            ("offset", "22"),
            ("lang", "it IT"),
            ("p1", "%22"),
            ("p2 extra", "false!")
        ].map { item in
            URLQueryItem(name: item.0, value: item.1)
        }
        
        
        let req = HTTPRequest {
            $0.path = "user"
            $0.add(queryItems: queryParams)
        }
        
        let urlRequest = try req.urlRequest(inClient: client)
        let rComps = URLComponents(string: urlRequest.url!.absoluteString)
        
        // Validate the host, scheme and path
        XCTAssert(rComps?.host == "api.github.com", "Invalid host name")
        XCTAssert(rComps?.scheme == "https", "Invalid scheme")
        XCTAssert(rComps?.path == "/user", "Invalid path")
        
        // Extract the encoded query items from the URL
        let encodedQueryItems: [(String, String)] = rComps!.url!.absoluteString[rComps!.rangeOfQuery!]
            .components(separatedBy: "&")
            .map { param in
                let values = param.components(separatedBy: "=")
                return (values[0], values[1])
            }.sorted {
                $0.0 < $1.0
            }
        
        // Encode original query params
        let cs = CharacterSet.urlQueryAllowed
        let originalQueryItems: [(String, String)] = queryParams.map { qItem in
            (qItem.name.addingPercentEncoding(withAllowedCharacters: cs) ?? "",
             qItem.value?.addingPercentEncoding(withAllowedCharacters: cs) ?? "")
        }.sorted {
            $0.0 < $1.0
        }

        XCTAssert(encodedQueryItems.count == originalQueryItems.count, "Different query items encoded")
        
        for i in 0..<encodedQueryItems.count {
            XCTAssert(encodedQueryItems[i].0 == originalQueryItems[i].0, "Query item key is not what we expect")
            XCTAssert(encodedQueryItems[i].1 == originalQueryItems[i].1, "Query item value is not what we expect")
        }
    }
    
    /// This test check if the body of the request is correctly assigned when it's a raw data.
    func testRequest_rawBody() async throws {
        guard let rawImageURL = Bundle.module.url(forResource: "test_rawdata", withExtension: "png") else {
            throw TestError("Failed to found assets file")
        }

        let rawImageData = try Data(contentsOf: rawImageURL)
        
        let req = HTTPRequest {
            $0.path = "/image/test_image"
            $0.body.content = rawImageData
            $0.method = .post
        }

        // Check the request
        let urlRequest = try req.urlRequest(inClient: client)
        let urlRequestComponents = urlRequest.urlComponents
        XCTAssert(urlRequest.method == req.method, "Method used is not the same set")
        XCTAssert(urlRequestComponents?.path == req.path, "Path set is not the same set")

        let response = try await req.fetch(client)
        XCTAssert(rawImageData == response.data, "Body is not the same we sent")
    }
    
    /// Test the encoding of a raw string for a request.
    func testRequest_stringBody() async throws {
        let body = "This an amazing post with emoji 👍"
        let req = HTTPRequest {
            $0.path = "/image/test_image"
            $0.body.content = body
            $0.method = .post
        }
        
        let response = try await req.fetch(client)
        XCTAssert(response.data?.asString() == body, "Body is not the same we sent")
    }
    
    func testRequest_urlParametersBody() async throws {
        let urlParamsBody = HTTPBody.URLParametersData([
            "page": "1",
            "offset": "22",
            "another param": "value!&",
            "p2": "👍",
            "p3": false,
            "p4": ["a","b"],
            "p5": ["k1": "v1", "k2": false]
        ])
        let encodedBody = try! urlParamsBody.encodedData()
                
        let req = HTTPRequest {
            $0.path = "/image/test_image"
            $0.body.content = urlParamsBody
            $0.method = .post
        }
        
        let urlRequest = try req.urlRequest(inClient: client)
                
        // Ensure params are inside the body and not in query string
        XCTAssert(urlRequest.body != nil, "Request message should containt the encoded url parameters")
        XCTAssert(urlRequest.url!.absoluteString.contains("page") == false, "Encoded params should be not in url query")
        
        // Ensure the encoded data is correct
        let response = try await req.fetch(client)
        XCTAssert(encodedBody == response.data, "Data should be equal")
        
        // Ensure special objects are encoded correctly
        let parsedParams = ParsedParams(string: response.data!.asString()!, decode: true)

        XCTAssert(parsedParams.params("p3").first?.value == "0", "Failed to encode the boolean value")
        XCTAssert(parsedParams.params("p2").first?.value == "👍", "Failed to encode the utf8 value")

        // Ensure array are encoded with brakets (by default)
        let arrayParams = parsedParams.params("p4[]")
        XCTAssert(arrayParams.count == 2, "Failed to encode an array value value")
        for param in arrayParams {
            XCTAssert((urlParamsBody.parameters?["p4"] as? [String])?.contains(param.value) ?? false,
                      "Failed to get encoded value in result")
        }
        
        // Ensure dictionary is encoded correctly
        XCTAssert(parsedParams.params("p5[k1]").first?.value == "v1", "Failed to encode dictionary")
        XCTAssert(parsedParams.params("p5[k2]").first?.value == "0", "Failed to encode dictionary")
    }
    
    func testRequest_urlParametersBodyAltEncoding() async throws {
        let urlParamsBody = HTTPBody.URLParametersData([
            "p3": false,
            "p4": ["a","b"]
        ])
        urlParamsBody.boolEncoding = .asLiterals
        urlParamsBody.arrayEncoding = .noBrackets
        
        
        let req = HTTPRequest {
            $0.path = "/image/test_image"
            $0.body.content = urlParamsBody
            $0.method = .post
        }
        
        let response = try await req.fetch(client)
        let parsedParams = ParsedParams(string: response.data!.asString()!, decode: true)
        
        
        XCTAssert(parsedParams.params("p3").first?.value == "false", "Failed to encode boolean")
        XCTAssert(parsedParams.params("p4").count == 2, "Failed to encode array")
    }
    
    func testRequest_stream() async throws {
        guard let rawImageURL = Bundle.module.url(forResource: "test_rawdata", withExtension: "png") else {
            throw TestError("Failed to found assets file")
        }
        
        let data = try Data(contentsOf: rawImageURL)
        
        let req = HTTPRequest {
            $0.path = "/image/test_image"
            $0.body = .stream(.fileURL(rawImageURL))
            $0.transferMode = .largeData
            $0.method = .post
        }
        
        let response = try await req.fetch(client)
        XCTAssert(response.data?.count == data.count, "Failed to transfer all data")
    }
    
    /// Note: this task uses a remote server so it's more an integration test.
    func testRequest_longRunningDownloadWithProgress() async throws {
        HTTPStubber.shared.disable() // we should connect to the remote network
        var progressionReports = 0
        
        let req = HTTPRequest {
            $0.url = URL(string: "http://ipv4.download.thinkbroadband.com/5MB.zip")!
            $0.transferMode = .largeData
            $0.method = .get
        }
        
        req.$progress.sink { progress in
            progressionReports += 1
        }.store(in: &observerBag)
        
        let response = try await req.fetch(client)
        XCTAssert(progressionReports > 0, "Failed to receive updates from 5MB file download")
        XCTAssert(response.data?.count ?? 0 > 0, "Failed to receive data")

        HTTPStubber.shared.enable()
    }
    
    func testRequest_longRunningDownloadWithResume() async throws {
        HTTPStubber.shared.disable() // we should connect to the remote network

        let partDownloadURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("partial-download")

        let req = HTTPRequest {
            $0.url = URL(string: "http://ipv4.download.thinkbroadband.com/100MB.zip")!
            $0.transferMode = .largeData
            $0.method = .get
        }
        
        req.$progress.sink { progress in
            print("Progress: \(progress?.percentage ?? 0)")
        }.store(in: &observerBag)
        
        // At certain point we want to break the download
        /*DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1, execute: {
            // And produce some resumable data for test
            req.cancel { partialData in
                print("Resumed data: \(partialData?.count ?? 0)")
                req.partialData = partialData
            }
        })*/
        
        // Start the first download
        let _ = try await req.fetch(client)
  
        // Attempt to resume the download
       // let _ = try await req.fetch(client)

        HTTPStubber.shared.enable()

    }
    
}

fileprivate struct ParsedParams {
    typealias ParamPair = (key: String, value: String)
    
    let params: [ParamPair]
    
    init(string: String, decode: Bool) {
        let rawParams = string.components(separatedBy: "&")
        self.params = rawParams.compactMap({ rawParam in
            let values = rawParam.components(separatedBy: "=")
            if let key = (decode ? values[0].removingPercentEncoding : values[0]),
               let value = (decode ? values[1].removingPercentEncoding : values[1]) {
                return (key, value)
            } else {
                return nil
            }
        })
    }
    
    func params(_ key: String) -> [ParamPair] {
        params.filter { item in
            item.key == key
        }
    }
    
}
