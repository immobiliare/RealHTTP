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
    func test_validateFullRequestURL() throws {
        let fullURL = URL(string: "http://127.0.0.1:8080")!
        let req = HTTPRequest {
            $0.url = fullURL
        }
        
        let urlRequest = try req.urlRequest(inClient: client)
        XCTAssert(urlRequest.url == fullURL, "We expect a full URL to replace the baseURL, we got '\(urlRequest.url?.absoluteString ?? "")'")
    }
    
    /// Using an IP it should still works returning the full URL and ignoring the client's base url.
    func test_validateFullRequestURLWithIP() throws {
        let fullURL = URL(string: "http://127.0.0.1:8080")!
        let req = HTTPRequest {
            $0.url = fullURL
        }
        
        let urlRequest = try req.urlRequest(inClient: client)
        XCTAssert(urlRequest.url == fullURL, "We expect a full URL, we got '\(urlRequest.url?.absoluteString ?? "")'")
    }
    
    /// If we specify just the path of an URL the final URL must be the
    /// URL of the request composed with the destination client's baseURL.
    func test_validateRelativeRequestURL() throws {
        let req = HTTPRequest {
            $0.path = "user"
        }
        
        let urlRequest = try req.urlRequest(inClient: client)
        let expectedURL = URL(string: "\(client.baseURL!.absoluteString)\(req.path)")
        XCTAssert(urlRequest.url == expectedURL, "We expect composed URL, we got: '\(urlRequest.url?.absoluteString ?? "")'")
    }
    
    /// This test verify the query parameters you can add to the url.
    func test_validateQueryParameters() throws {
        HTTPStubber.shared.enable()

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
        
        HTTPStubber.shared.disable()
    }
    
    /// This test check if the body of the request is correctly assigned when it's a raw data.
    func test_validateRawDataBody() async throws {
        HTTPStubber.shared.enable()

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
        
        HTTPStubber.shared.disable()
    }
    
    /// Test the encoding of a raw string for a request.
    func test_validateStringBody() async throws {
        HTTPStubber.shared.enable()

        let body = "This an amazing post with emoji 👍"
        let req = HTTPRequest {
            $0.path = "/image/test_image"
            $0.body.content = body
            $0.method = .post
        }
        
        let response = try await req.fetch(client)
        XCTAssert(response.data?.asString() == body, "Body is not the same we sent")
        
        HTTPStubber.shared.disable()
    }
    
    func test_validateURLParamsBody() async throws {
        HTTPStubber.shared.enable()

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
        
        HTTPStubber.shared.disable()
    }
    
    func test_validateURLParametersBodyAltEncoding() async throws {
        HTTPStubber.shared.enable()

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
        
        HTTPStubber.shared.disable()
    }
    
    func test_streamUpload() async throws {
        HTTPStubber.shared.enable()

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
        
        HTTPStubber.shared.disable()
    }
    
    /// Note: this task uses a remote server so it's more an integration test.
    func test_largeFileDownloadWithProgress() async throws {
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
    
    // Test the resumable download.
    func test_largeFileTestResume() async throws {
        HTTPStubber.shared.disable() // we should connect to the remote network
        
        var resumeEventOccurred = false
        var resumedDownloadFinished = false

        let req = HTTPRequest {
            $0.url = URL(string: "http://ipv4.download.thinkbroadband.com/5MB.zip")!
            $0.transferMode = .largeData
            $0.method = .get
        }
        
        req.$progress.sink { progress in
            print("Progress: \(progress?.percentage ?? 0)")
            if progress?.event == .resumed {
                resumeEventOccurred = true
            } else if progress?.percentage == 1 {
                resumedDownloadFinished = true
            }
        }.store(in: &observerBag)
        
        // At certain point we want to break the download
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.5, execute: {
            // And produce some resumable data for test
            req.cancel { partialData in
                print("Produced partial data: \(partialData?.count ?? 0) bytes")
                req.partialData = partialData // set the partial data to request to allows resume!
            }
        })
        
        // Start the first download
        let _ = try await req.fetch(client)
  
        // Attempt to resume the download
        let _ = try await req.fetch(client)

        HTTPStubber.shared.enable()

        XCTAssert(resumeEventOccurred, "Failed to resume download")
        XCTAssert(resumedDownloadFinished, "Failed to complete resumed download")
    }
    
    // Test JSON encoding via Codable
    func test_json_decodeWithCodable() async throws {
        HTTPStubber.shared.enable()
        
        guard let rawImageURL = Bundle.module.url(forResource: "test_rawdata", withExtension: "png") else {
            throw TestError("Failed to found assets file")
        }
                
        let avatarImageData = try Data(contentsOf: rawImageURL)
        let user = TestUser(firstName: "Mark",
                            lastName: "Ross",
                            age: 26,
                            bornDate: Date(),
                            info: .init(acceptedLicense: true, avatar: avatarImageData))

        let req = try HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8080")!
            $0.method = .post
            $0.body = try .json(user)
        }
        
        let response = try await req.fetch(client)
        let responseUser = try response.decode(TestUser.self)
        
        XCTAssert(response.headers[.contentType]?.contains("application/json") ?? false, "Invalid content type")
        XCTAssert((response.headers[.contentLength]?.isEmpty ?? true) == false, "Invalid content length")
        XCTAssert(responseUser == user, "Failed to correctly send/decode codable object")
        
        HTTPStubber.shared.disable()
    }
    
    /// A simple JSON request using JSONObjectSerialization
    func test_json_decodeRawData() async throws {
        HTTPStubber.shared.enable()

        let jsonData: [String: Any] = [
            "user" : "Mark",
            "age": 12,
            "data": [
                "born": "2021-01-01",
                "acceptedLicense": true
            ],
            "some_string": "bla bla bla".data?.base64EncodedString() ?? ""
        ]
        
        let req = try HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8080")!
            $0.method = .post
            $0.body = try .json(jsonData)
        }
        
        let response = try await req.fetch(client)
        let rDict = try response.decodeJSONData([String: Any].self)
        
        let rUser: String? = rDict?.valueForKeyPath(keyPath: "user")
        XCTAssert(rUser == "Mark", "Invalid decode of a key")

        let rBorn: String? = rDict?.valueForKeyPath(keyPath: "data.born")
        XCTAssert(rBorn == "2021-01-01", "Invalid decode of a key")
        
        let base64Origin: String? = jsonData.valueForKeyPath(keyPath: "some_string")
        let rBase64: String? = rDict?.valueForKeyPath(keyPath: "some_string")
        XCTAssert(base64Origin == rBase64, "Invalid decode of a key")
  
        XCTAssert(response.headers[.contentType]?.contains("application/json") ?? false, "Invalid content type")
        XCTAssert((response.headers[.contentLength]?.isEmpty ?? true) == false, "Invalid content length")
   
        HTTPStubber.shared.disable()
    }
    
    // MARK: - Multipart Form Data
    
    func test_multipartFormData_contentTypeContainsBoundary() throws {
        let boundary = HTTPBody.MultipartForm.Boundary()
        let body = HTTPBody.multipart(boundary: boundary.id) { _ in }
                
        let formData = (body.content as? HTTPBody.MultipartForm)
        
        let expectedContentType = "multipart/form-data; boundary=\(boundary.id)"
        XCTAssertEqual(formData!.contentType, expectedContentType, "contentType should match expected value")
    }
    
    func test_multipartFormData_contentLengthMatchesTotalBodyPartSize() {
        let data1 = Data("Lorem ipsum dolor sit amet.".utf8)
        let data2 = Data("Vim at integre alterum.".utf8)
        
        let body = HTTPBody.multipart({
            $0.add(data: data1, name: "data1")
            $0.add(data: data2, name: "data2")
        })
        let multipartFormData = (body.content as? HTTPBody.MultipartForm)

        // Then
        let expectedContentLength = UInt64(data1.count + data2.count)
        XCTAssertEqual(multipartFormData?.contentLength,
                       expectedContentLength,
                       "content length should match expected value")
    }
    
    /// Test Multipart-Form Data
    func test_multipartFormData_encoding() async throws {
        HTTPStubber.shared.enable()

        let data = Data("Lorem ipsum dolor sit amet.".utf8)
        
        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8080")!
            $0.method = .post
            $0.body = .multipart({ form in
                form.add(data: data, name: "data")
            })
        }
        
        // Encoded data should be not nil
        let encodedData = try req.body.content.encodedData()
        XCTAssertNotNil(encodedData, "encoded data should not be nil")

        // Verify the encoded string format
        if let form = req.body.content as? HTTPBody.MultipartForm {
            let delimiter = "--\(form.boundaryID)".data(using: .utf8)!
            let crlf = "\r\n".data(using: .utf8)!
            
            let expectedData: Data = (
                delimiter + crlf +
                "Content-Disposition: form-data; name=\"data\"".data(using: .utf8)! + crlf + crlf +
                data + crlf
            )
                        
            XCTAssertEqual(encodedData, expectedData, "encoded data should match expected data")
        }
        
        HTTPStubber.shared.disable()
    }
    
    func test_multipartFormData_encodingBodyParts() throws {
        HTTPStubber.shared.enable()

        let frenchData = Data("français".utf8)
        let japaneseData = Data("日本語".utf8)
        let emojiData = Data("😃👍🏻🍻🎉".utf8)
        
        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8080")!
            $0.method = .post
            $0.body = .multipart({ form in
                form.add(data: frenchData, name: "french")
                form.add(data: japaneseData, name: "japanese", mimeType: MIMEType.textPlain.rawValue)
                form.add(data: emojiData, name: "emoji", mimeType: MIMEType.textPlain.rawValue)
            })
        }

        // Encoded data should be not nil
        let encodedData = try req.body.content.encodedData()
        XCTAssertNotNil(encodedData, "Encoded data should not be nil")

        // Verify the encoded string format
        if let form = req.body.content as? HTTPBody.MultipartForm {
            let delimiter = "--\(form.boundaryID)".data(using: .utf8)!
            let crlf = "\r\n".data(using: .utf8)!
            
            let expectedData: Data = (
                delimiter + crlf +
                "Content-Disposition: form-data; name=\"french\"".data(using: .utf8)! + crlf + crlf +
                "français".data(using: .utf8)! + crlf +
                delimiter + crlf +
                "Content-Disposition: form-data; name=\"japanese\"".data(using: .utf8)! + crlf +
                "Content-Type: text/plain".data(using: .utf8)! + crlf + crlf +
                "日本語".data(using: .utf8)! + crlf +
                delimiter + crlf +
                "Content-Disposition: form-data; name=\"emoji\"".data(using: .utf8)! + crlf +
                "Content-Type: text/plain".data(using: .utf8)! + crlf + crlf +
                "😃👍🏻🍻🎉".data(using: .utf8)! +
                crlf
            )
            XCTAssertEqual(encodedData, expectedData, "encoded data should match expected data")
        }
        
        HTTPStubber.shared.disable()
    }
    
    func test_multipartFormData_encodingFileBodyPart() throws {
        HTTPStubber.shared.enable()

        guard let rawImageURL = Bundle.module.url(forResource: "test_rawdata", withExtension: "png") else {
            throw TestError("Failed to found assets file")
        }
        
        let req = try HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8080")!
            $0.method = .post
            $0.body = try .multipart({ form in
                try form.add(fileURL: rawImageURL, name: "finder")
            })
        }

        // Encoded data should be not nil
        let encodedData = try req.body.content.encodedData()
        XCTAssertNotNil(encodedData, "Encoded data should not be nil")

        // Verify the encoded string format
        if let form = req.body.content as? HTTPBody.MultipartForm {
            let delimiter = "--\(form.boundaryID)".data(using: .utf8)!
            let crlf = "\r\n".data(using: .utf8)!
            
            let imageData = try Data(contentsOf: rawImageURL)
            
            let expectedData: Data = (
                delimiter + crlf +
                "Content-Disposition: form-data; name=\"finder\"; filename=\"test_rawdata.png\"".data(using: .utf8)! + crlf +
                "Content-Type: image/png".data(using: .utf8)! + crlf + crlf +
                imageData +
                crlf
            )
            
            XCTAssertEqual(encodedData, expectedData, "encoded data should match expected data")
            
            HTTPStubber.shared.disable()
        }
    }
    
    func test_multipartFormData_encodingMultipleFileBodyParts() throws {
        HTTPStubber.shared.enable()
        
        guard let image1URL = Bundle.module.url(forResource: "test_rawdata", withExtension: "png"),
              let image2URL = Bundle.module.url(forResource: "mac_icon", withExtension: "jpg")
        else {
            throw TestError("Failed to found assets files")
        }
        
        let req = try HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8080")!
            $0.method = .post
            $0.body = try .multipart({ form in
                try form.add(fileURL: image1URL, name: "image1")
                try form.add(fileURL: image2URL, name: "image2")
            })
        }
        
        // Encoded data should be not nil
        let encodedData = try req.body.content.encodedData()
        XCTAssertNotNil(encodedData, "Encoded data should not be nil")
        
        // Verify the encoded string format
        if let form = req.body.content as? HTTPBody.MultipartForm {
            let delimiter = "--\(form.boundaryID)".data(using: .utf8)!
            let crlf = "\r\n".data(using: .utf8)!
            
            let image1Data = try Data(contentsOf: image1URL)
            let image2Data = try Data(contentsOf: image2URL)
            
            let expectedData: Data = (
                delimiter + crlf +
                "Content-Disposition: form-data; name=\"image1\"; filename=\"test_rawdata.png\"".data(using: .utf8)! + crlf +
                "Content-Type: image/png".data(using: .utf8)! + crlf + crlf +
                image1Data + crlf +
                delimiter + crlf +
                "Content-Disposition: form-data; name=\"image2\"; filename=\"mac_icon.jpg\"".data(using: .utf8)! + crlf +
                "Content-Type: image/jpeg".data(using: .utf8)! + crlf + crlf +
                image2Data + crlf
            )
            
            try expectedData.write(to: URL(fileURLWithPath: "/Users/daniele/Desktop/expected.txt"))
            try encodedData.write(to: URL(fileURLWithPath: "/Users/daniele/Desktop/original.txt"))

            XCTAssertEqual(encodedData, expectedData, "encoded data should match expected data")
        }
        
        HTTPStubber.shared.disable()
    }
    
    
}

public func + (lhs: Data, rhs: Data) -> Data {
    var newData = lhs
    newData.append(rhs)
    return newData
}

// MARK: - Support Structures

fileprivate struct TestUser: Codable, Equatable {
    var firstName: String
    var lastName: String
    var age: Int
    var bornDate: Date?
    var info: Info
    
    struct Info: Codable, Equatable {
        var acceptedLicense: Bool
        var avatar: Data
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

fileprivate extension Dictionary {
    
    /// Get the value at specified keypath.
    ///
    /// - Returns: T?
    func valueForKeyPath<T>(keyPath: String) -> T? {
        var keys = keyPath.components(separatedBy: ".")
        guard let first = keys.first as? Key else {
            return nil
        }

        guard let value = self[first] else {
            return nil
        }
        
        keys.remove(at: 0)
        if !keys.isEmpty, let subDict = value as? [NSObject : AnyObject] {
            let rejoined = keys.joined(separator: ".")
            return subDict.valueForKeyPath(keyPath: rejoined)
        }
        
        return value as? T
    }
    
}
