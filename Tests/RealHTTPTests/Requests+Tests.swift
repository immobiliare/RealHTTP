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

class RequestsTests: XCTestCase {
    
    private var observerBag = Set<AnyCancellable>()
    
    private func setupStubber(echo: Bool = true) {
        HTTPStubber.shared.enable()
        HTTPStubber.shared.removeAllStubs()
        
        if echo {
            HTTPStubber.shared.add(stub: try! HTTPStubRequest().match(urlRegex: "(?s).*").stubEcho())
        }
    }
    
    private func stopStubber() {
        HTTPStubber.shared.disable()
    }
    
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
        
        //HTTPStubber.shared.enable()
        
       // let echo = HTTPStubRequest().match(urlRegex: "*").stubEcho()
       // HTTPStubber.shared.add(stub: echo)
    }
    
    override class func tearDown() {
        HTTPStubber.shared.removeAllStubs()
        HTTPStubber.shared.disable()
        super.tearDown()
    }
    
    func test_isAbsoluteURLTest() async throws {
        let dataArray: [(url: String, expected: Bool)] = [
            ("/connect/login", false), // false, path
            ("connect/login", false), // false, path
            ("http://www.mydomain.com/api/v1", true), // true
            ("http://www.mydomain.com/api/v1?param1=value", true), // true
            ("https://www.mydomain.com/api/v1?param1=value", true), // true
            ("localhost:3434/api/v1?param1=value", true), // true - localhost
            ("/myfolder/test.txt", false), // false - relative URL
            ("test", false), // false - also relative URL
            ("HTTP://EXAMPLE.COM'", true), // true - HTTP upper-case absolute URL
            ("http://example.com", true), // true - regular http absolute URL
            ("/redirect?target=http://example.org", false)
        ]
        
        for data in dataArray {
            let isAbs = data.url.isAbsoluteURL
            let expectedValue = data.expected
            print("  [\(isAbs) should be \(expectedValue)]:\t \(data.url)")
            if isAbs != data.expected {
                print("FAIL \(data.url)")
            }
            //XCTAssertEqual(isAbs, data.expected)
        }
    }
    
    // MARK: - URL Composition Tests
    
    /// We tests how replacing the `url` property the final executed url does
    /// not contains the `baseURL` of the destination `HTTPClient` instance.
    func test_validateFullRequestURL() async throws {
        let fullURL = URL(string: "http://127.0.0.1:8080")!
        let req = HTTPRequest {
            $0.url = fullURL
        }
        
        let urlRequest = try await req.urlRequest(inClient: client)
        XCTAssert(urlRequest.url == fullURL, "We expect a full URL to replace the baseURL, we got '\(urlRequest.url?.absoluteString ?? "")'")
    }
    
    /// Using an IP it should still works returning the full URL and ignoring the client's base url.
    func test_validateFullRequestURLWithIP() async throws {
        let fullURL = URL(string: "http://127.0.0.1:8080")!
        let req = HTTPRequest {
            $0.url = fullURL
        }
        
        let urlRequest = try await req.urlRequest(inClient: client)
        XCTAssert(urlRequest.url == fullURL, "We expect a full URL, we got '\(urlRequest.url?.absoluteString ?? "")'")
    }
    
    /// If we specify just the path of an URL the final URL must be the
    /// URL of the request composed with the destination client's baseURL.
    func test_validateRelativeRequestURL() async throws {
        let req = HTTPRequest {
            $0.path = "user"
        }
        
        let urlRequest = try await req.urlRequest(inClient: client)
        let expectedURL = URL(string: "\(client.baseURL!.absoluteString)/\(req.path)")
        XCTAssert(urlRequest.url == expectedURL, "We expect composed URL, we got: '\(urlRequest.url?.absoluteString ?? "")'")
    }
    
    /// This test verify the query parameters you can add to the url.
    func test_validateQueryParameters() async throws {
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
        
        let urlRequest = try await req.urlRequest(inClient: client)
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
        setupStubber(echo: true)
        defer { stopStubber() }

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
        let urlRequest = try await req.urlRequest(inClient: client)
        let urlRequestComponents = urlRequest.urlComponents
        XCTAssert(urlRequest.method == req.method, "Method used is not the same set")
        XCTAssert(urlRequestComponents?.path == req.path, "Path set is not the same set")

        let response = try await req.fetch(client)
        XCTAssert(rawImageData == response.data, "Body is not the same we sent")
    }
    
    /// Test the encoding of a raw string for a request.
    func test_validateStringBody() async throws {
        setupStubber(echo: true)
        defer { stopStubber() }
        
        let body = "This an amazing post with emoji 👍"
        let req = HTTPRequest {
            $0.path = "/image/test_image"
            $0.body.content = body
            $0.method = .post
        }
        
        let response = try await req.fetch(client)
        XCTAssert(response.data?.asString == body, "Body is not the same we sent")
    }
    
    func test_validateURLParamsBody() async throws {
        setupStubber(echo: true)
        defer { stopStubber() }
        
        let urlParamsBody = HTTPBody.URLParametersData([
            "page": "1",
            "offset": "22",
            "another param": "value!&",
            "p2": "👍",
            "p3": false,
            "p4": ["a","b"],
            "p5": ["k1": "v1", "k2": false]
        ])
        let encodedBody = try! urlParamsBody.serializeData().data
                
        let req = HTTPRequest {
            $0.path = "/image/test_image"
            $0.body.content = urlParamsBody
            $0.method = .post
        }
        
        let urlRequest = try await req.urlRequest(inClient: client)
                
        // Ensure params are inside the body and not in query string
        XCTAssert(urlRequest.body != nil, "Request message should containt the encoded url parameters")
        XCTAssert(urlRequest.url!.absoluteString.contains("page") == false, "Encoded params should be not in url query")
        
        // Ensure the encoded data is correct
        let response = try await req.fetch(client)
        XCTAssert(encodedBody == response.data, "Data should be equal")
        
        // Ensure special objects are encoded correctly
        let parsedParams = ParsedParams(string: response.data!.asString!, decode: true)

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
    
    func test_validateURLParametersBodyAltEncoding() async throws {
        setupStubber(echo: true)
        defer { stopStubber() }
        
        let urlParamsBody = HTTPBody.URLParametersData([
            "p3": false,
            "p4": ["a","b"]
        ],
                                                       boolEncoding: .asLiterals,
                                                       arrayEncoding: .noBrackets)
        
        let req = HTTPRequest {
            $0.path = "/image/test_image"
            $0.body.content = urlParamsBody
            $0.method = .post
        }
        
        let response = try await req.fetch(client)
        let parsedParams = ParsedParams(string: response.data!.asString!, decode: true)
        
        
        XCTAssert(parsedParams.params("p3").first?.value == "false", "Failed to encode boolean")
        XCTAssert(parsedParams.params("p4").count == 2, "Failed to encode array")
    }
    
    func test_streamUpload() async throws {
        setupStubber(echo: true)
        defer { stopStubber() }
        
        guard let rawImageURL = Bundle.module.url(forResource: "test_rawdata", withExtension: "png") else {
            throw TestError("Failed to found assets file")
        }
        
        let data = try Data(contentsOf: rawImageURL)
        
        let req = HTTPRequest {
            $0.path = "/image/test_image"
            $0.body = .stream(.fileURL(rawImageURL), contentType: .png)
            $0.transferMode = .largeData
            $0.method = .post
        }
        
        let response = try await req.fetch(client)
        XCTAssert(response.data?.count == data.count, "Failed to transfer all data")
    }
    
    /// Note: this task uses a remote server so it's more an integration test.
    func test_largeFileDownloadWithProgress() async throws {
        stopStubber()
        
        var progressionReports = 0
        
        let req = HTTPRequest {
            $0.url = URL(string: "http://ipv4.download.thinkbroadband.com/5MB.zip")!
            $0.transferMode = .largeData
            $0.method = .get
        }
        
        req.$progress.sink { progress in
            progressionReports += 1
            print("Downloading \(progress?.percentage ?? 0)")
        }.store(in: &observerBag)
        
        let response = try await req.fetch(client)
        XCTAssert(progressionReports > 0, "Failed to receive updates from 5MB file download")
        XCTAssert(response.data?.count ?? 0 > 0, "Failed to receive data")
        XCTAssertNotNil(response.dataFileURL, "Failed to store file")
    }
    
    func test_largeFileProgressActivity() async throws {
        stopStubber()

        var progressValues = [HTTPProgress]()
        
        let req = HTTPRequest {
            $0.url = URL(string: "http://ipv4.download.thinkbroadband.com/5MB.zip")!
            $0.transferMode = .largeData
            $0.method = .get
        }
        
        req.$progress.sink { progress in
            if let progress = progress {
                progressValues.append(progress)
            }
        }.store(in: &observerBag)
        
        let _ = try await req.fetch(client)
        
        // Check the progress
        var previousProgress: Double = progressValues.first?.percentage ?? 0.0
        
        for progress in progressValues {
            XCTAssertGreaterThanOrEqual(progress.percentage, previousProgress)
            previousProgress = progress.percentage
        }
        
        if let lastProgressValue = progressValues.last?.percentage {
            XCTAssertEqual(lastProgressValue, 1.0)
        } else {
            XCTFail("last item in progressValues should not be nil")
        }
    }
    
    // Test the resumable download.
    func test_largeFileTestResume() async throws {
        stopStubber()
        
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

        XCTAssert(resumeEventOccurred, "Failed to resume download")
        XCTAssert(resumedDownloadFinished, "Failed to complete resumed download")
    }
    
    // Test JSON encoding via Codable
    func test_jsonDecodeWithCodable() async throws {
        setupStubber(echo: true)
        defer { stopStubber() }
        
        guard let rawImageURL = Bundle.module.url(forResource: "test_rawdata", withExtension: "png") else {
            throw TestError("Failed to found assets file")
        }
                
        let avatarImageData = try Data(contentsOf: rawImageURL)
        let user = TestUser(firstName: "Mark",
                            lastName: "Ross",
                            age: 26,
                            bornDate: Date(),
                            info: .init(acceptedLicense: true, avatar: avatarImageData))

        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8080")!
            $0.method = .post
            $0.body = .json(user)
        }
        
        let response = try await req.fetch(client)
        let responseUser = try response.decode(TestUser.self)
        
        XCTAssert(response.headers[.contentType]?.contains("application/json") ?? false, "Invalid content type")
        XCTAssert((response.headers[.contentLength]?.isEmpty ?? true) == false, "Invalid content length")
        XCTAssert(responseUser == user, "Failed to correctly send/decode codable object")
    }
    
    /// A simple JSON request using JSONObjectSerialization
    func test_jsonDecodeRawData() async throws {
        setupStubber(echo: true)
        defer { stopStubber() }
        
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
    }
    
    
    func test_jsonEncoderCanBeCustomized() async throws {
        let newClient = HTTPClient(baseURL: nil)
    
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8081/initial")!
            $0.body = .json(TestParameters.default, encoder: encoder)
        }
        
        let request = try await req.urlRequest(inClient: newClient)

        let expected = """
        {
          "property" : "property"
        }
        """
        XCTAssertEqual(request.httpBody?.asString, expected)
    }
    
    func test_jsonEncoderSortedKeysHasSortedKeys() async throws {
        let newClient = HTTPClient(baseURL: nil)

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        
        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8081/initial")!
            $0.body = .json(["z": "z", "a": "a", "p": "p"], encoder: encoder)
        }
        
        let request = try await req.urlRequest(inClient: newClient)

        let expected = """
        {"a":"a","p":"p","z":"z"}
        """
        XCTAssertEqual(request.httpBody?.asString, expected)
    }
    
    
    // MARK: - Validators
    
    func test_responseValidationSequence() async throws {
        setupStubber(echo: true)
        defer { stopStubber() }
        
        var passedValidators = 0
        let errorMessage = "It should be fail! that's okay"
        
        // Setup a custom client
        let newClient = HTTPClient(baseURL: nil)
        newClient.validators = [
            CallbackValidator { response, request in
                passedValidators += 1
                return .nextValidator
            },
            CallbackValidator { response, request in
                passedValidators += 1
                return .nextValidator
            },
            CallbackValidator { response, request in
                passedValidators += 1
                return .failChain(TestError(stringLiteral: errorMessage))
            },
            CallbackValidator { response, request in
                passedValidators += 1 // it should never arrive here
                return .nextValidator
            },
        ]
        
        // Setup request
        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8080")!
            $0.method = .post
        }
        
        let response = try await req.fetch(newClient)
        
        XCTAssert(response.isError == true, "Call should be invalidated by the last provider")
        XCTAssert(passedValidators == 3, "Call should be invalidated by the last provider")
        XCTAssert(response.error?.message == errorMessage, "Error from call must be overriden by the validator's error")
    }
    
    func test_retryMechanism() async throws {
        setupStubber(echo: true)
        defer { stopStubber() }
        
        let maxAttempts = 5
        let respondOkAtAttempt = 3
        
        let newClient = HTTPClient(baseURL: nil)
        newClient.validators = [
            CallbackValidator { response, request in
                if request.currentRetry == respondOkAtAttempt {
                    return .nextValidator
                }
                
                return .retry(.immediate)
            }
        ]

        // Setup request
        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8080")!
            $0.method = .post
            $0.body = .string("test")
            $0.maxRetries = maxAttempts
        }
        
        let response = try await req.fetch(newClient)
        
        XCTAssert(req.currentRetry == 3, "Failed to retry \(respondOkAtAttempt) times as expected")
        XCTAssert(response.data?.asString == "test", "Expected response not satisfied")
    }
    
    
    /// The following test is used to validate the output error provided by a validator when it trigger
    /// the chain failure. We want to check if the error is reported correctly as it
    /// <https://github.com/immobiliare/RealHTTP/issues/34>
    func test_checkValidatorCustomErrorThrowing() async throws {
        setupStubber(echo: false)
        defer { stopStubber() }

        // Prepare client and validator
        let newClient = HTTPClient(baseURL: nil)
        newClient.validators.insert(CustomValidator(callback: { response, request in
            let error = MyError(title: "My Custom Message")
            return .failChain(error)
        }), at: 0)
        
        // Add stubber
        let stub = try! HTTPStubRequest().match(urlRegex: "/initial").stub(for: .get) { urlRequest, _ in
            let response = HTTPStubResponse()
            response.body = "ciao"
            return response
        }
        HTTPStubber.shared.add(stub: stub)
        
        // Setup request
        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8080")!
            $0.method = .post
            $0.body = .string("test")
        }
        
        let response = try await req.fetch(newClient)
        let customUnderlyingError = response.error?.error as? MyError

        XCTAssertNotNil(customUnderlyingError, "Failed to receive the correct error")
        XCTAssertEqual(response.error?.category, .validatorFailure, "Failed to intercept the correct error category")
    }
    
    /// The following test is used to validate the output error provided by a validator when it trigger
    /// the chain failure. We want to check if the error is reported correctly also when using
    /// the decode function as it:
    /// <https://github.com/immobiliare/RealHTTP/issues/34>
    func test_checkValidatorCustomErrorThrowingToDecodeFunction() async throws {
        setupStubber(echo: false)
        defer { stopStubber() }
        
        struct DummyDecodeStruct: Decodable {}

        // Prepare client and validator
        let newClient = HTTPClient(baseURL: nil)
        newClient.validators.insert(CustomValidator(callback: { response, request in
            let error = MyError(title: "My Custom Message")
            return .failChain(error)
        }), at: 0)
        
        // Add stubber
        let stub = try! HTTPStubRequest().match(urlRegex: "/initial").stub(for: .get) { urlRequest, _ in
            let response = HTTPStubResponse()
            response.body = "ciao"
            return response
        }
        HTTPStubber.shared.add(stub: stub)
        
        // Setup request
        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8080")!
            $0.method = .post
            $0.body = .string("test")
        }
        
        do {
            // We try to decode a function which fails with decode because an error is throwed at fetch stage
            // So we would to get the throwed error outside the decode.
            _ = try await req.fetch(client: newClient, DummyDecodeStruct.self)
            XCTFail("Fetch+Decode should fail")
        } catch {
            let customUnderlyingError = (error as? HTTPError)?.error as? MyError
            XCTAssertNotNil(customUnderlyingError, "Failed to receive the correct error")
        }
    }
    
    /// The following test check different error types returned by a request.
    func test_checkNetworkStatusCodes() async throws {
        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8080/req")!
        }
        
        let someErrors: [HTTPStatusCode] = [
            .tooManyRequests,
            .badGateway,
            .unauthorized,
            .forbidden,
            .gatewayTimeout
        ]
        
        for error in someErrors {
            let response = try await generateResponseForRequest(req) { urlRequest, stubRequest in
                let response = HTTPStubResponse()
                response.statusCode = error
                return response
            }
            XCTAssertEqual(response.error?.statusCode, error)
        }
    }
    
    func test_maxAttemptsNetworkErrorThrow() async throws {
        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8080/req")!
            $0.maxRetries = 3
        }
        
        let defaultValidator = HTTPDefaultValidator()
        defaultValidator.retriableHTTPStatusCodes = [.gatewayTimeout: 0]
       
        let response = try await generateResponseForRequest(req, validators: [defaultValidator]) { urlRequest, stubRequest in
            let response = HTTPStubResponse()
            response.statusCode = .gatewayTimeout
            return response
        }
        
        XCTAssertEqual(response.error?.category, .retryAttemptsReached)
    }
    
    func generateResponseForRequest(_ request: HTTPRequest, validators: [HTTPValidator] = [],
                                    stubResponse callback: @escaping ((URLRequest, HTTPStubRequest) -> HTTPStubResponse)) async throws -> HTTPResponse {
        setupStubber(echo: false)
        defer { stopStubber() }
        
        let regex = String(request.path.dropFirst())
        let stub = try! HTTPStubRequest().match(urlRegex: regex).stub(for: .get, responseProvider: callback)
        HTTPStubber.shared.add(stub: stub)
        
        // Prepare client
        let newClient = HTTPClient(baseURL: nil)
        if !validators.isEmpty {
            newClient.validators = validators
        }
        
        let response = try await request.fetch(newClient)
        return response
    }
    
    /// The following test allows us to test a modified version of the response via validator.
    /// Using a custom validator we can return a copy of the original response shightly modified useing a custom subclass.
    func test_validatorWithModifiedResponse() async throws {
        setupStubber(echo: false)
        
        let stubOriginRequest = try! HTTPStubRequest().match(urlRegex: "/someCall").stub(for: .get, responseProvider: { request, stubRequest in
            let response = HTTPStubResponse()
            response.contentType = .jsonUTF8
            response.statusCode = .ok
            response.body = """
                { "message": "OK", "letters" : ["a","b","c","d"] }
            """
            return response
        })
        HTTPStubber.shared.add(stub: stubOriginRequest)

        /// Our custom response is a subclass of the HTTPResponse
        class MyCustomResponse: HTTPResponse {
            var customObject: CustomObject?
            
            public override init(response: HTTPResponse) {
                super.init(response: response)
            }
            
        }
        
        /// This is a dummy object to decode for our tests.
        struct CustomObject: Codable {
            var message: String
            var letters: [String]
        }
        
        /// Validator allows us to return a custom response.
        class CustomValidator: HTTPValidator {
            
            func validate(response: HTTPResponse, forRequest request: HTTPRequest) -> HTTPResponseValidatorResult {
                /// Return a copy of the original response as subclass and modify it.
                do {
                    let custom = MyCustomResponse.init(response: response)
                    custom.customObject = try custom.decode(CustomObject.self)
                    return .nextValidatorWithResponse(custom)
                } catch {
                    return .failChain(error)
                }
            }
            
        }
        
        let newClient = HTTPClient(baseURL: nil)

        let customValidator = CustomValidator()
        newClient.validators.insert(customValidator, at: 0)

        // Prepare the request
        let originRequest = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8080/someCall")!
        }
        
        let response = try await newClient.fetch(originRequest)
        print(String(describing: response))
        
        // Check if our response is the one we modified.
        guard let customResponse = response as? MyCustomResponse else {
            XCTFail("Expected MyCustomResponse")
            return
        }
        
        XCTAssertNotNil(customResponse.customObject)
        XCTAssert(customResponse.customObject?.message == "OK")
        
        stopStubber()
    }
    
    func test_altRequestValidator() async throws {
        let successBodyPrefix = "SUCCESS_"
        
        // Validate success at first attempt
        let (r1Request, r1Response) = try await altRequestValidator(maxRetriesForOriginCall: 3, succedOnRetry: 1, responsePrefix: successBodyPrefix)
        XCTAssertEqual(r1Response.data?.asString, "\(successBodyPrefix)1", "Failed to execute a success with no retry")
        XCTAssertEqual(r1Request.currentRetry, 1)
        XCTAssertNil(r1Response.error)

      
        // Validate the success at second attempt
        let (r2Request, r2Response) = try await altRequestValidator(maxRetriesForOriginCall: 3, succedOnRetry: 2, responsePrefix: successBodyPrefix)
        XCTAssertEqual(r2Response.data?.asString, "\(successBodyPrefix)2", "Failed to execute a success retry")
        XCTAssertEqual(r2Request.currentRetry, 2)
        XCTAssertNil(r2Response.error)

        // Validate the failure at third attempt
        let (r3Request, r3Response) = try await altRequestValidator(maxRetriesForOriginCall: 3, succedOnRetry: 4, responsePrefix: successBodyPrefix)
        XCTAssertEqual(r3Request.currentRetry, 3, "Failed to retry the expected number of times")
        XCTAssertNotNil(r3Response.error)
    }
    
    private func altRequestValidator(maxRetriesForOriginCall: Int, succedOnRetry: Int, responsePrefix: String) async throws -> (request: HTTPRequest, response: HTTPResponse) {
        setupStubber(echo: false)

        var retryMade = 0
        
        // Prepare the stub responses
        
        let stubOriginRequest = try! HTTPStubRequest().match(urlRegex: "/someAuthCall").stub(for: .get, responseProvider: { request, stubRequest in
            let response = HTTPStubResponse()

            if succedOnRetry == retryMade {
                // respond ok only when succeded is triggered...
                response.body = "\(responsePrefix)\(retryMade)"
                response.statusCode = .ok
            } else {
                // ... otherwise we'll deny all
                response.statusCode = .unauthorized
            }
            
            retryMade += 1
            return response
        })
        HTTPStubber.shared.add(stub: stubOriginRequest)
        
        let stubRefreshToken = try! HTTPStubRequest().match(urlRegex: "/refreshToken").stub(for: .get, responseProvider: { request, stubRequest in
            let response = HTTPStubResponse()
            response.statusCode = .ok
            response.body = "NEW_TOKEN"
            return response
        })
        HTTPStubber.shared.add(stub: stubRefreshToken)

        // Prepare the validator
        
        let newClient = HTTPClient(baseURL: nil)
        
        let altValidator = HTTPAltRequestValidator(statusCodes: [.unauthorized]) { request, response in
            HTTPRequest {
                $0.method = .get
                $0.url = URL(string: "http://127.0.0.1:8080/refreshToken")!
            }
        } onReceiveAltResponse: { request, response in
            let newToken = response.data?.asString ?? "NONE"
            newClient.headers.set("X-API-TOKEN", newToken)
        }
        
        newClient.validators.insert(altValidator, at: 0)

        
        // Prepare the request
        let originRequest = HTTPRequest {
            $0.method = .get
            $0.timeout = 60
            $0.maxRetries = maxRetriesForOriginCall
            $0.url = URL(string: "http://127.0.0.1:8080/someAuthCall")!
        }
        
        let response = try await newClient.fetch(originRequest)
        
        stopStubber()
        
        return (originRequest, response)
    }
    
    func test_retryMechanismAfterAltRequest() async throws {
        setupStubber(echo: true)
        defer { stopStubber() }
        
        var receivedAltCallResponse: String?
        
        let altReq = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8080")!
            $0.method = .post
            $0.body = .string("loginAndRetry")
        }
        
        let newClient = HTTPClient(baseURL: nil)
        newClient.validators = [
            CallbackValidator { response, request in
                if request === altReq {
                    // alternate request return success
                    return .nextValidator
                }
                
                if request.currentRetry == 0 {
                    // first call attempt retry return after executing alt call
                    return .retry(.after(altReq, 0, { request, response in
                        receivedAltCallResponse = response.data?.asString
                    }))
                } else {
                    // the next time is okay
                    return .nextValidator
                }
            }
        ]

        // Setup request
        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8080")!
            $0.method = .post
            $0.maxRetries = 3
            $0.body = .string("doSomething")
        }
        
        let response = try await req.fetch(newClient)
        let responseString = response.data?.asString
        XCTAssert(responseString == "doSomething", "Response received after retry with alt call is wrong")
        XCTAssert(receivedAltCallResponse == "loginAndRetry", "Response received on alt call is wrong")
    }
    
    func test_retryMechanismAfterAltRequestAndFail() async throws {
        setupStubber(echo: false)
        defer { stopStubber() }
        
        var loginCallResponse: HTTPResponse?
        let loginCallErrorResponse = "login failed! check credentials"
        let mainCallErrorResponse = "login required"
        
        // Network calls
        let req = HTTPRequest {
            $0.maxRetries = 3
            $0.url = URL(string: "http://127.0.0.1:8080/execute")!
        }
        let loginCall = HTTPRequest {
            $0.maxRetries = 3
            $0.url = URL(string: "http://127.0.0.1:8080/login")!
        }
        
        let newClient = HTTPClient(baseURL: nil)
        newClient.validators = [
            CallbackValidator { response, request in
                if request === loginCall {
                    return .nextValidator
                } else {
                    return .retry(.after(loginCall, 0, { request, response in
                        loginCallResponse = response
                    }))
                }
                
            }
        ]

        // Stubber to catch /execute call
        let stubReq = try! HTTPStubRequest().match(urlRegex: "/execute").stub(for: .get) { response in
            response.statusCode = .unauthorized
            response.body = mainCallErrorResponse
        }
        HTTPStubber.shared.add(stub: stubReq)
        
        let altStubReq = try! HTTPStubRequest().match(urlRegex: "/login").stub(for: .get) { response in
            response.statusCode = .internalServerError
            response.body = loginCallErrorResponse
        }
        HTTPStubber.shared.add(stub: altStubReq)
        
        // Execute
        let response = try await req.fetch(newClient)
        
        // Check alternate call
        XCTAssert(loginCallResponse?.statusCode == .internalServerError, "Login call should fail with internal server error")
        XCTAssert(loginCallResponse?.data?.asString == loginCallErrorResponse, "Failed to validate login call error")

        // Check main call
        XCTAssert(response.statusCode == .unauthorized, "Main call should fail with unathorized")
        XCTAssert(response.data?.asString == mainCallErrorResponse, "Failed to validate main call error")
    }
    
    func test_POSTRequestWithUnicodeParameters() async throws {
        setupStubber(echo: true)
        defer { stopStubber() }
        
        let parameters = ["french": "français",
                          "japanese": "日本語",
                          "arabic": "العربية",
                          "emoji": "😃"]
        
        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8080/execute")!
            $0.method = .post
            $0.body = .form(values: parameters)
        }
        
        // Execute
        let response = try await req.fetch()

        
        // Verify
        XCTAssertNotNil(response.data)
        
        if let dataString = response.data?.asString,
               let forms = URLComponents(string: "http://example.com?\(dataString)") {
                   XCTAssertEqual(forms.valueForQueryItem("french"), parameters["french"])
                   XCTAssertEqual(forms.valueForQueryItem("japanese"), parameters["japanese"])
                   XCTAssertEqual(forms.valueForQueryItem("arabic"), parameters["arabic"])
                   XCTAssertEqual(forms.valueForQueryItem("emoji"), parameters["emoji"])
               } else {
                   XCTFail("Failed to validate fields")
               }
    }
    
    func test_POSTRequestWithBase64EncodedImages() async throws {
        setupStubber(echo: true)
        
        // Given
        let pngBase64EncodedString: String = {
            let fileURL = url(forResource: "test_rawdata", withExtension: "png")
            let data = try! Data(contentsOf: fileURL)

            return data.base64EncodedString(options: .lineLength64Characters)
        }()

        let jpegBase64EncodedString: String = {
            let fileURL = url(forResource: "mac_icon", withExtension: "jpg")
            let data = try! Data(contentsOf: fileURL)

            return data.base64EncodedString(options: .lineLength64Characters)
        }()

        let parameters = [
            "email": "user@realhttp.com",
            "png_image": pngBase64EncodedString,
            "jpeg_image": jpegBase64EncodedString
        ]

        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8080/execute")!
            $0.method = .post
            $0.body = .form(values: parameters)
        }
        
        // Execute
        let response = try await req.fetch()

        // Then
        XCTAssertNotNil(response.data)
        XCTAssertEqual(response.isError, false)

        if let dataString = response.data?.asString,
               let forms = URLComponents(string: "http://example.com?\(dataString)") {
            XCTAssertEqual(forms.valueForQueryItem("email"), parameters["email"])
            XCTAssertEqual(forms.valueForQueryItem("png_image"), parameters["png_image"])
            XCTAssertEqual(forms.valueForQueryItem("jpeg_image"), parameters["jpeg_image"])
        } else {
            XCTFail("Failed to validate fields")
        }
    }
    
    func test_downloadWithTimeout() async throws {
        setupStubber(echo: false)
        defer { stopStubber() }
        
        let stub = try! HTTPStubRequest().match(urlRegex: "/login").stub(for: .get, interval: .delayedBy(10), code: .ok)
        HTTPStubber.shared.add(stub: stub)
        
        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8080/login")!
            $0.method = .get
            $0.timeout = 3
        }
        
        let response = try await req.fetch()

        if let error = response.error?.category {
            XCTAssertEqual(error, HTTPError.ErrorCategory.timeout)
            XCTAssertNil(response.data)
        } else {
            XCTFail("Network call should fail")
        }
    }
    
    func test_combineFetchPublisher() {
        stopStubber()
        
        let exp = expectation(description: "Waiting for sink result")

        let newClient = HTTPClient(baseURL: nil)
        let req = HTTPRequest {
            $0.url = URL(string: "https://jsonplaceholder.typicode.com/todos/1")!
            $0.method = .get
            $0.timeout = 20
        }
        
        req.fetchPublisher(in: newClient).sink { _ in

        } receiveValue: { response in
            XCTAssertNotNil(response.data)
            exp.fulfill()
        }.store(in: &observerBag)

        wait(for: [exp], timeout: 20)
    }

    func test_urlRequestModifierInterceptor() async throws {
        setupStubber(echo: true)
        defer { stopStubber() }
        
        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8080/execute")!
            $0.method = .post
            $0.body = .form(values: ["p1" : "1", "p2": "asc"])
        }
        
        req.urlRequestModifier = { urlRequest in
            urlRequest.method = .patch
            urlRequest.httpBody = "some data".data(using: .utf8)
            urlRequest.allowsCellularAccess = false
            urlRequest.setValue("Value", forHTTPHeaderField: "X-HEADER")
        }
        
        // Execute
        let response = try await req.fetch()
        
        XCTAssertEqual(response.urlRequests.original?.method, .patch)
        XCTAssertEqual(response.data?.asString, "some data")
        XCTAssertEqual(response.urlRequests.original?.allowsCellularAccess, false)
        XCTAssertEqual(response.urlRequests.original?.allHTTPHeaderFields?["X-HEADER"], "Value")
    }
    
    func test_testFollowRedirectRefuse() async throws {
        setupStubber(echo: false)
        defer { stopStubber() }
        
        let newClient = HTTPClient(baseURL: nil)
        
        setupStubsForRedirectTest()
        
        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8081/login")!
            $0.method = .get
            $0.timeout = 100
            $0.redirectMode = .refuse
        }
    
        // Execute
        let response = try await req.fetch(newClient)
        
        XCTAssertEqual(response.statusCode, .found)
        XCTAssertTrue(response.data?.asString?.contains("Location:") ?? false)
    }
    
    func test_followRedirectRefuse() async throws {
        setupStubber(echo: false)
        defer { stopStubber() }
        
        let newClient = HTTPClient(baseURL: nil)
        
        setupStubsForRedirectTest()
        
        let req = setupRequestRedirect(.refuse)
        let response = try await req.fetch(newClient)
        
        XCTAssertEqual(response.statusCode, .found)
        XCTAssertTrue(response.data?.asString?.contains("Location:") ?? false)
    }
    
    func test_followRedirectFollow() async throws {
        setupStubber(echo: false)
        defer { stopStubber() }
        
        let newClient = HTTPClient(baseURL: nil)
        
        setupStubsForRedirectTest()
        
        let req = setupRequestRedirect(.follow)
        let response = try await req.fetch(newClient)
        
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertTrue(response.data?.asString?.contains("redirected") ?? false)
    }
    
    public func test_interceptUrlRequestModifier() async throws {
        setupStubber(echo: false)
        defer { stopStubber() }
        
        let newClient = HTTPClient(baseURL: nil)

        let stubInitial = try! HTTPStubRequest().match(urlRegex: "/initial").stub(for: .get) { response in
            response.statusCode = .ok
        }
        HTTPStubber.shared.add(stub: stubInitial)
        
        let stubModified = try! HTTPStubRequest().match(urlRegex: "/modified").stub(for: .get) { response in
            response.statusCode = .badRequest
        }
        HTTPStubber.shared.add(stub: stubModified)
        
        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8081/initial")!
            $0.method = .get
            $0.urlRequestModifier = { req in
                req.url = URL(string: "http://127.0.0.1:8081/modified")!
            }
        }
        
        let response = try await req.fetch(newClient)
        XCTAssertEqual(response.statusCode, .badRequest)
    }
    
    func test_cURLRequestGETDescription() async throws {
        let newClient = HTTPClient(baseURL: nil)

        let url = URL(string: "http://127.0.0.1:8081/initial")!
        let req = HTTPRequest {
            $0.url = url
            $0.method = .get
        }
        
        let cURLDesc = try await req.cURLDescription(whenIn: newClient)
        let components = cURLCommandComponents(from: cURLDesc)

        // Then
        XCTAssertEqual(components[0..<3], ["$", "curl", "-v"])
        XCTAssertTrue(components.contains("-X") == true)
        XCTAssertEqual(components.last, "\"\(url)\"")
    }
    
    func test_cURLRequestWithCustomHeader() async throws {
        let newClient = HTTPClient(baseURL: nil)

        let url = URL(string: "http://127.0.0.1:8081/initial")!
        let req = HTTPRequest {
            $0.url = url
            $0.method = .get
            $0.headers = .init(headers: [
                .init(name: "X-Custom-Header", value: "{\"key\": \"value\"}")
            ])
        }

        let cURLDesc = try await req.cURLDescription(whenIn: newClient)

        XCTAssertNotNil(cURLDesc.range(of: "-H \"X-Custom-Header: {\\\"key\\\": \\\"value\\\"}\""))
    }

    func test_cURLRequestPOSTDescription() async throws {
        let newClient = HTTPClient(baseURL: nil)

        let url = URL(string: "http://127.0.0.1:8081/initial")!
        let req = HTTPRequest {
            $0.url = url
            $0.method = .post
            $0.headers = .init(headers: [
                .init(name: "X-Custom-Header", value: "{\"key\": \"value\"}")
            ])
        }

        let cURLDesc = try await req.cURLDescription(whenIn: newClient)
        let components = cURLCommandComponents(from: cURLDesc)

        // Then
        XCTAssertEqual(components[0..<3], ["$", "curl", "-v"])
        XCTAssertEqual(components[3..<5], ["-X", "POST"])
        XCTAssertEqual(components.last, "\"\(url)\"")
    }
    
    func test_cURLRequestPOSTRequestWithJSONParameters() async throws {
        let newClient = HTTPClient(baseURL: nil)
        newClient.headers = .init()

        let url = URL(string: "http://127.0.0.1:8081/initial")!
        let req = HTTPRequest {
            $0.url = url
            $0.method = .post
            $0.headers = .init(headers: [
                .contentType(.json)
            ])
            $0.body = .json( ["foo": "bar",
                              "fo\"o": "b\"ar",
                              "f'oo": "ba'r"])
        }

        let cURLDesc = try await req.cURLDescription(whenIn: newClient)
        let components = cURLCommandComponents(from: cURLDesc)

        // Then
        XCTAssertEqual(components[0..<3], ["$", "curl", "-v"])
        XCTAssertEqual(components[3..<5], ["-X", "POST"])

        XCTAssertNotNil(cURLDesc.range(of: "-d \"{"))
        XCTAssertNotNil(cURLDesc.range(of: "\\\"f'oo\\\":\\\"ba'r\\\""))
        XCTAssertNotNil(cURLDesc.range(of: "\\\"fo\\\\\\\"o\\\":\\\"b\\\\\\\"ar\\\""))
        XCTAssertNotNil(cURLDesc.range(of: "\\\"foo\\\":\\\"bar\\"))
        XCTAssertNotNil(cURLDesc.range(of: "-H \"Content-Type: application/json\""))

        XCTAssertEqual(components.last, "\"\(url)\"")
    }
    
    func test_POSTRequestWithCookieCURLDescription() async throws {
        let newClient = HTTPClient(baseURL: nil)
        newClient.headers = .init()

        let url = URL(string: "http://127.0.0.1:8081/initial")!
        let cookie = HTTPCookie(properties: [.domain: url.host as Any,
                                             .path: url.path,
                                             .name: "foo",
                                             .value: "bar"])!
        
        newClient.cookieStorage?.setCookie(cookie)
        let req = HTTPRequest {
            $0.url = url
            $0.method = .post
            $0.headers = .init(headers: [
                .contentType(.json)
            ])
        }
        

        let cURLDesc = try await req.cURLDescription(whenIn: newClient)
        let components = cURLCommandComponents(from: cURLDesc)

        XCTAssertEqual(components[0..<3], ["$", "curl", "-v"])
        XCTAssertEqual(components[3..<5], ["-X", "POST"])
        XCTAssertEqual(components.last, "\"\(url)\"")
        XCTAssertEqual(components[5..<6], ["-b"])
    }
    
    public func test_urlSessionBasedOnTransferModeLarge() async throws {
        let newClient = HTTPClient(baseURL: nil)

        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8081/initial")!
            $0.transferMode = .largeData
        }
        
        let sessionRequest = try await req.urlSessionTask(inClient: newClient)
        XCTAssertNotNil(sessionRequest as? URLSessionDownloadTask)
    }
    
    public func test_urlSessionBasedOnTransferModeDefault() async throws {
        let newClient = HTTPClient(baseURL: nil)

        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8081/initial")!
            $0.transferMode = .default
        }
        
        let sessionRequest = try await req.urlSessionTask(inClient: newClient)
        XCTAssertNotNil(sessionRequest as? URLSessionDataTask)
    }
    
    func test_dataIsProperlyEncodedAndProperContentTypeIsSet() async throws {
        let newClient = HTTPClient(baseURL: nil)

        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8081/initial")!
            $0.body = .json(TestParameters.default)
        }

        let request = try await req.urlRequest(inClient: newClient)

        XCTAssertEqual(request.headers["Content-Type"], "application/json")
        XCTAssertEqual(request.httpBody?.asString, "{\"property\":\"property\"}")
    }
    
    func test_queryIsBodyEncodedAndProperContentTypeIsSetForPOSTRequest() async throws {
        let newClient = HTTPClient(baseURL: nil)

        let req = try HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8081/initial")!
            $0.body = try .form(object: TestParameters.default)
        }

        let request = try await req.urlRequest(inClient: newClient)

        // Then
        XCTAssertEqual(request.headers["Content-Type"], "application/x-www-form-urlencoded; charset=utf-8")
        XCTAssertEqual(request.httpBody?.asString, "property=property")
    }
    
    func test_encoderCanBeCustomized() async throws {
        let newClient = HTTPClient(baseURL: nil)

        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8081/initial")!
            $0.add(parameters: ["bool": true], boolEncoding: .asLiterals)
        }

        let request = try await req.urlRequest(inClient: newClient)
        
        // Then
        let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
        XCTAssertEqual(components?.percentEncodedQuery, "bool=true")
    }

    func test_encoderCanEncodeDecimalWithHighPrecision() async throws {
        let newClient = HTTPClient(baseURL: nil)

        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8081/initial")!
            $0.add(parameters: ["a": 1.123456])
        }

        let request = try await req.urlRequest(inClient: newClient)
        
        XCTAssertTrue(request.url?.absoluteString.contains("a=1.123456") ?? false)
    }
    
    // MARK: - Private Functions
    
    private func cURLCommandComponents(from cURLString: String) -> [String] {
        cURLString.components(separatedBy: .whitespacesAndNewlines)
            .filter { $0 != "" && $0 != "\\" }
    }
    
    private func setupRequestRedirect(_ redirect: HTTPRequest.RedirectMode) -> HTTPRequest {
        HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8081/login")!
            $0.method = .get
            $0.timeout = 100
            $0.redirectMode = redirect
        }
    }
    
    private func setupStubsForRedirectTest() {
        // Create redirect URL
        let redirectURL = URL(string: "http://127.0.0.1:8081/redirected")!
        let redirectStub = try! HTTPStubRequest().match(urlRegex: "/login").stub(method: .get, redirectsTo: redirectURL)
        HTTPStubber.shared.add(stub: redirectStub)
        
        // Create final URL
        let stubRedirect = try! HTTPStubRequest().match(urlRegex: "/redirected").stub(for: .get) { response in
            response.statusCode = .ok
            response.body = "redirected".data(using: .utf8)!
        }
        HTTPStubber.shared.add(stub: stubRedirect)
    }
    
    // MARK: - Requests Initialize
    
    func test_postRequestInitialization() async throws {
        let newClient = HTTPClient(baseURL: nil)
        
        let req = try HTTPRequest(method: .post, "https://jsonplaceholder.typicode.com/posts",
                                  body: try .json(["title": "foo", "body": "bar", "userId": 1]))
        req.timeout = 10
        let result = try await req.fetch(newClient)
        XCTAssertEqual(result.statusCode, .created)
    }
    
    func test_uriTemplateInitialization() async throws {
        let newClient = HTTPClient(baseURL: nil)
        
        let req = try HTTPRequest(URI: "https://jsonplaceholder.typicode.com/posts/{postId}",
                                  variables: ["postId": 1])
        let result = try await req.fetch(newClient)
        XCTAssertEqual(result.statusCode, .ok)
    }
    
    // MARK: - Transformers
    
    func test_responseTransformers() async throws {
        let newClient = HTTPClient(baseURL: nil)
        
        let bodyTransformer1 = HTTPResponseTransformer { response, _ in
            response.data = "replaced".data(using: .utf8)
            return response
        }
        let bodyTransformer2 = HTTPResponseTransformer { response, _ in
            let d = response.data?.asString ?? ""
            response.data = "\(d)_final".data(using: .utf8)
            return response
        }
        newClient.responseTransformers = [bodyTransformer1, bodyTransformer2]
        
        let req = try HTTPRequest(method: .post, "https://jsonplaceholder.typicode.com/posts",
                                  body: try .json(["title": "foo", "body": "bar", "userId": 1]))
        req.timeout = 10
        let result = try await req.fetch(newClient)
        XCTAssertEqual(result.data?.asString, "replaced_final")
    }
    
    // MARK: - Multipart Form Data Tests

    func test_multipartContainsContentTypeBoundary() async throws {
        let newClient = HTTPClient(baseURL: nil)

        let form = HTTPBody.MultipartForm()
        let req = HTTPRequest {
            $0.url = URL(string: "https://somedomain.com")
            $0.method = .post
            $0.body = .multipart(form)
        }
        
        let request = try await req.urlRequest(inClient: newClient)

        let expContentType = "multipart/form-data; boundary=\(form.boundary.id)"
        XCTAssertEqual(request.headers["Content-Type"], expContentType)
    }
    
    func test_multipartContentLengthMatchesTotalBodyPartSize() async throws {
        let newClient = HTTPClient(baseURL: nil)

        let data1 = Data("Lorem ipsum dolor sit amet.".utf8)
        let data2 = Data("Vim at integre alterum.".utf8)

        let form = HTTPBody.MultipartForm()
        
        form.add(data: data1, name: "data_1")
        form.add(data: data2, name: "data_2")

        let req = HTTPRequest {
            $0.url = URL(string: "https://somedomain.com")
            $0.method = .post
            $0.body = .multipart(form)
        }
        
        let request = try await req.urlRequest(inClient: newClient)

        let expectedContentLength = UInt64(data1.count + data2.count)
        XCTAssertTrue(request.headers[.contentLength] == String(expectedContentLength), "Content-length should match expected value")
    }
    
    func test_multipartEncodingTestForFormItems() async throws {
        let newClient = HTTPClient(baseURL: nil)

        let form = HTTPBody.MultipartForm()
        
        // String
        try form.add(string: "some value", name: "parameter_1")

        // Raw Data
        form.add(data: "{ \"key\": \"val\" }".data(using: .utf8)!,
                 name: "raw", fileName: "file_text", mimeType: HTTPContentType.json.rawValue)
        
        // File
        let fileURL = url(forResource: "mac_icon", withExtension: "jpg")
        try form.add(fileURL: fileURL, name: "file")
                
        let req = HTTPRequest {
            $0.url = URL(string: "https://somedomain.com")
            $0.method = .post
            $0.body = .multipart(form)
        }
        
        let request = try await req.urlRequest(inClient: newClient)
        
        // Check the boundary string
        let expContentType = "multipart/form-data; boundary=\(form.boundary.id)"
        XCTAssertEqual(request.headers["Content-Type"], expContentType)
        
        // Check form data
        let data = request.body?.asString(encoding: .ascii)
                
        let expectedFileHeader = """
        --\(form.boundaryID)\r
        Content-Disposition: form-data; name="file"; filename="mac_icon.jpg"\r
        Content-Type: image/jpeg\r
        """
        
        let expectedJSONData = "--\(form.boundaryID)\r\nContent-Disposition: form-data; name=\"raw\"; filename=\"file_text\"\r\nContent-Type: application/json\r\n\r\n{ \"key\": \"val\" }"
        
        let expectedStringData = "--\(form.boundaryID)\r\nContent-Disposition: form-data; name=\"parameter_1\"\r\n\r\nsome value"
        
        XCTAssertTrue(data!.contains(expectedFileHeader), "Missing file header")
        XCTAssertTrue(data!.contains(expectedJSONData), "Missing JSON Raw Data+Header")
        XCTAssertTrue(data!.contains(expectedStringData), "Missing String+Header")
    }
    
    func test_multipartEncodingDataBodyPart() async throws {
        let newClient = HTTPClient(baseURL: nil)

        let form = HTTPBody.MultipartForm()
     
        let data = Data("Lorem ipsum dolor sit amet.".utf8)
        form.add(data: data, name: "data")
        
        let req = HTTPRequest {
            $0.url = URL(string: "https://somedomain.com")
            $0.method = .post
            $0.body = .multipart(form)
        }
        
        let request = try await req.urlRequest(inClient: newClient)
                
        XCTAssertNotNil(request.body, "Encoded data should not be nil")
        let expectedString = (
            "--\(form.boundaryID)\r\n" +
            "Content-Disposition: form-data; name=\"data\"\r\n\r\n" +
            "Lorem ipsum dolor sit amet." + "\r\n" +
            "--\(form.boundaryID)--\r\n"
        )
        let expectedData = Data(expectedString.utf8)
        XCTAssertEqual(request.body, expectedData, "Encoded data should match expected data")
    }
    
    func test_multipartEncodingMultipleDataBodyParts() async throws {
        let newClient = HTTPClient(baseURL: nil)

        let frenchData = Data("français".utf8)
        let japaneseData = Data("日本語".utf8)
        let emojiData = Data("😃👍🏻🍻🎉".utf8)
        
        let form = HTTPBody.MultipartForm()
        
        form.add(data: frenchData, name: "french")
        form.add(data: japaneseData, name: "japanese", mimeType: "text/plain")
        form.add(data: emojiData, name: "emoji", mimeType: "text/plain")
        
        let req = HTTPRequest {
            $0.url = URL(string: "https://somedomain.com")
            $0.method = .post
            $0.body = .multipart(form)
        }
        
        let request = try await req.urlRequest(inClient: newClient)
            
        let expectedString = (
            "--\(form.boundaryID)\r\n" +
            "Content-Disposition: form-data; name=\"french\"" + "\r\n\r\n" +
            "français" +
            "\r\n"+"--\(form.boundaryID)\r\n" +
            "Content-Disposition: form-data; name=\"japanese\"" + "\r\n" +
            "Content-Type: text/plain" + "\r\n" + "\r\n"  +
            "日本語" +
            "\r\n"+"--\(form.boundaryID)\r\n" +
            "Content-Disposition: form-data; name=\"emoji\"" + "\r\n" +
            "Content-Type: text/plain" + "\r\n" + "\r\n" +
            "😃👍🏻🍻🎉" + "\r\n" +
            "--\(form.boundaryID)--\r\n"
        )
        let expectedData = Data(expectedString.utf8)
        XCTAssertEqual(request.body, expectedData, "Encoded data should match expected data")
    }
    
    func test_multipartEncodingFileBodyPart() async throws {
        let newClient = HTTPClient(baseURL: nil)

        let form = HTTPBody.MultipartForm()

        let unicornImageURL = url(forResource: "test_rawdata", withExtension: "png")
        try form.add(fileURL: unicornImageURL, name: "unicorn")
        
        let req = HTTPRequest {
            $0.url = URL(string: "https://somedomain.com")
            $0.method = .post
            $0.body = .multipart(form)
        }
        
        let request = try await req.urlRequest(inClient: newClient)
                
        let clrf = "\r\n".data(using: .utf8)!
        let imageData = try! Data(contentsOf: unicornImageURL)

        let expectedData = (
            "--\(form.boundaryID)".data(using: .utf8)! + clrf +
            "Content-Disposition: form-data; name=\"unicorn\"; filename=\"test_rawdata.png\"".data(using: .utf8)! + clrf +
            "Content-Type: image/png".data(using: .utf8)! + clrf + clrf +
            imageData + clrf +
            "--\(form.boundaryID)--".data(using: .utf8)! + clrf
        )
        
        XCTAssertEqual(request.body, expectedData, "Data should match expected data")
    }
    
    func test_multipartEncodingStreamBodyPart() async throws {
        let newClient = HTTPClient(baseURL: nil)

        let form = HTTPBody.MultipartForm()

        let unicornImageURL = url(forResource: "test_rawdata", withExtension: "png")
        let unicornDataLength = UInt64((try! Data(contentsOf: unicornImageURL)).count)
        let unicornStream = InputStream(url: unicornImageURL)!
        
        form.add(stream: unicornStream,
                 withLength: unicornDataLength,
                 name: "unicorn",
                 fileName: "unicorn.png",
                 mimeType: "image/png")

        let req = HTTPRequest {
            $0.url = URL(string: "https://somedomain.com")
            $0.method = .post
            $0.body = .multipart(form)
        }
        
        let request = try await req.urlRequest(inClient: newClient)

        XCTAssertNotNil(request.body, "Encoded data should not be nil")

        var expectedData = Data()
        let crlf = "\r\n".data(using: .utf8)!

        expectedData.append("--\(form.boundaryID)".data(using: .utf8)! + crlf)
        expectedData.append("Content-Disposition: form-data; name=\"unicorn\"; filename=\"unicorn.png\"".data(using: .utf8)! + crlf)
        expectedData.append("Content-Type: image/png".data(using: .utf8)! + crlf + crlf)

        expectedData.append(try! Data(contentsOf: unicornImageURL) + crlf)
        expectedData.append("--\(form.boundaryID)--".data(using: .utf8)! + crlf)
        
        XCTAssertEqual(request.body, expectedData, "Data should match expected data")
    }
    
    func test_queryParamsFromClientAndRequest() async throws {
        // test with full absolute url
        try await queryParametersRequestForURL(requestFullURL: URL(string: "https://somedomain.com/path"),
                                               path: nil,
                                               baseClientURL: nil,
                                               expBaseURL: "https://somedomain.com/path?")
        // test with relative composed url
        try await queryParametersRequestForURL(requestFullURL: nil,
                                               path: "path",
                                               baseClientURL: URL(string: "https://somedomain.com"),
                                               expBaseURL: "https://somedomain.com/path?")
    }
    
    /// The following test check the exclusive write access to the internal HTTPDataLoader's running task container
    /// and verify no exc_bad_access error can be triggered due multiple access from several threads.
    func test_concurrentNetworkCallsDataLoaderTest() async throws {
        HTTPStubber.shared.enable()
        HTTPStubber.shared.removeAllStubs()
        HTTPStubber.shared.add(stub: try! HTTPStubRequest().match(urlRegex: "(?s).*").stubEcho())
        
        var requests = [HTTPRequest]()
        let newClient = HTTPClient(baseURL: nil)

        for _ in 0..<10000 {
            let req = try! HTTPRequest(method: .post, "https://www.apple.com",
                                      body: try .json(["title": "foo", "body": "bar", "userId": 1]))
            
            requests.append(req)
        }
        
        await withThrowingTaskGroup(of: HTTPResponse.self, body: { group in
            for req in requests {
                group.addTask(priority: .high) {
                    let result = try await req.fetch(newClient)
                    print(result.data?.asString ?? "")
                    return result
                }
            }
            
        })
    }
    
    func queryParametersRequestForURL(requestFullURL: URL?, path: String?, baseClientURL: URL?, expBaseURL: String) async throws {
        let clientQueryItems = [
            URLQueryItem(name: "client_query_param_1", value: "value_1"),
            URLQueryItem(name: "client_query_param_2", value: "value_2")
        ]
        
        let newClient = HTTPClient(baseURL: baseClientURL)
        newClient.queryParams = clientQueryItems
        
        let reqQueryItems = [
            URLQueryItem(name: "r_query_param_1", value: "value_1"),
            URLQueryItem(name: "r_query_param_2", value: "value_2")
        ]
        
        let req = HTTPRequest {
            if let path = path {
                $0.path = path
            } else {
                $0.url = requestFullURL
            }
            $0.method = .post
            $0.add(queryItem: reqQueryItems.first!)
            $0.addQueryParameter(name: reqQueryItems.last!.name, value: reqQueryItems.last!.value!)
        }
        
        let request = try await req.urlRequest(inClient: newClient)
        guard let reqQueryItems = request.urlComponents?.queryItems, reqQueryItems.isEmpty == false else {
            XCTFail("Failed to use queryParams")
            return
        }
                
        // Validate query item parameters.
        clientQueryItems.forEach { qItem in
            XCTAssertTrue(reqQueryItems.contains(where: { rQItem in
                rQItem.name == qItem.name && rQItem.value == qItem.value
            }), "Failed to validate client's query items")
        }
        
        // Validate request's query parameters.
        reqQueryItems.forEach { qItem in
            XCTAssertTrue(reqQueryItems.contains(where: { rQItem in
                rQItem.name == qItem.name && rQItem.value == qItem.value
            }), "Failed to validate requests's query items")
        }
        
        // Validate URL composer
        let validateBaseURL = request.url!.absoluteString.hasPrefix(expBaseURL)
        XCTAssertTrue(validateBaseURL, "Failed to validate the url of the request")
    }
    
    public func testStub() async throws {
        HTTPStubber.shared.enable()
        
        let x = randomString(length: 1000)
        print(x)
        
        let stub = try HTTPStubRequest().match(urlRegex: "(?s).*")
            .stub(for: .get, code: .ok, interval: .withConnection(.speedSlow), contentType: .text, body: x)
        HTTPStubber.shared.add(stub: stub)
        
        let req = HTTPRequest {
            $0.method = .get
            $0.timeout = 120
            $0.url = URL(string: "http://www.google.com")
        }
        let f = try await req.fetch()
        print(f.data?.asString ?? "")
    }
    
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
        
}

public struct UserCredentials: Codable {
    var username: String
    var pwd: String
}


// MARK: - Support Structures

struct TestParameters: Encodable {
    static let `default` = TestParameters(property: "property")

    let property: String
}

func url(forResource: String, withExtension: String) -> URL {
    guard let fileURL = Bundle.module.url(forResource: forResource, withExtension: withExtension) else {
        fatalError("Failed to retrive assets")
    }
    
    return fileURL
}

fileprivate struct CallbackValidator: HTTPValidator {
    
    var onValidate: ((_ response: HTTPResponse, _ request: HTTPRequest) -> HTTPResponseValidatorResult)?
    
    func validate(response: HTTPResponse, forRequest request: HTTPRequest) -> HTTPResponseValidatorResult {
        onValidate?(response, request) ?? .nextValidator
    }
    
}

public func + (lhs: Data, rhs: Data) -> Data {
    var newData = lhs
    newData.append(rhs)
    return newData
}

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

// MARK: - ErrorMessageValidator

fileprivate class CustomValidator: HTTPValidator {
    public typealias Callback = ((HTTPResponse, HTTPRequest) -> HTTPResponseValidatorResult)
    
    public var callback: Callback
    
    public init(callback: @escaping Callback) {
        self.callback = callback
    }

    public func validate(response: HTTPResponse, forRequest request: HTTPRequest) -> HTTPResponseValidatorResult {
        callback(response, request)
    }
    
}

fileprivate struct MyError: Error {
    public let title: String

    public init(title: String) {
        self.title = title
    }
    
}
