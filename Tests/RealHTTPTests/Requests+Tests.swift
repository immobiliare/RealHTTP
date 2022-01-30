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
            HTTPStubber.shared.add(stub: HTTPStubRequest().match(urlRegex: "*").stubEcho())
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
        let urlRequest = try req.urlRequest(inClient: client)
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
        ])
        urlParamsBody.boolEncoding = .asLiterals
        urlParamsBody.arrayEncoding = .noBrackets
        
        
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
            $0.body = .stream(.fileURL(rawImageURL))
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
    
    
    func test_jsonEncoderCanBeCustomized() throws {
        let newClient = HTTPClient(baseURL: nil)
    
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let req = try HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8081/initial")!
            $0.body = try .json(TestParameters.default, encoder: encoder)
        }
        
        let request = try req.urlRequest(inClient: newClient)

        let expected = """
        {
          "property" : "property"
        }
        """
        XCTAssertEqual(request.httpBody?.asString, expected)
    }
    
    func test_jsonEncoderSortedKeysHasSortedKeys() throws {
        let newClient = HTTPClient(baseURL: nil)

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        
        let req = try HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8081/initial")!
            $0.body = try .json(["z": "z", "a": "a", "p": "p"], encoder: encoder)
        }
        
        let request = try req.urlRequest(inClient: newClient)

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
            $0.url = URL(string: "http://127.0.0.1:8080/execute")!
        }
        let loginCall = HTTPRequest {
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
        let stubReq = HTTPStubRequest().match(urlRegex: "/execute").stub(for: .get) { response in
            response.statusCode = .unauthorized
            response.body = mainCallErrorResponse
        }
        HTTPStubber.shared.add(stub: stubReq)
        
        let altStubReq = HTTPStubRequest().match(urlRegex: "/login").stub(for: .get) { response in
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

        let parameters = ["email": "user@realhttp.com",
                          "png_image": pngBase64EncodedString,
                          "jpeg_image": jpegBase64EncodedString]


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
        
        let stub = HTTPStubRequest().match(urlRegex: "/login").stub(for: .get, delay: 10, code: .ok)
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
        }
        
        req.fetchPublisher(in: newClient).sink { _ in

        } receiveValue: { response in
            XCTAssertNotNil(response.data)
            exp.fulfill()
        }.store(in: &observerBag)

        wait(for: [exp], timeout: 10)
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

        let stubInitial = HTTPStubRequest().match(urlRegex: "/initial").stub(for: .get) { response in
            response.statusCode = .ok
        }
        HTTPStubber.shared.add(stub: stubInitial)
        
        let stubModified = HTTPStubRequest().match(urlRegex: "/modified").stub(for: .get) { response in
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
    
    func test_cURLRequestGETDescription() {
        let newClient = HTTPClient(baseURL: nil)

        let url = URL(string: "http://127.0.0.1:8081/initial")!
        let req = HTTPRequest {
            $0.url = url
            $0.method = .get
        }
        
        let cURLDesc = req.cURLDescription(whenIn: newClient)
        let components = cURLCommandComponents(from: cURLDesc)

        // Then
        XCTAssertEqual(components[0..<3], ["$", "curl", "-v"])
        XCTAssertTrue(components.contains("-X") == true)
        XCTAssertEqual(components.last, "\"\(url)\"")
    }
    
    func test_cURLRequestWithCustomHeader() {
        let newClient = HTTPClient(baseURL: nil)

        let url = URL(string: "http://127.0.0.1:8081/initial")!
        let req = HTTPRequest {
            $0.url = url
            $0.method = .get
            $0.headers = .init(headers: [
                .init(name: "X-Custom-Header", value: "{\"key\": \"value\"}")
            ])
        }

        let cURLDesc = req.cURLDescription(whenIn: newClient)

        XCTAssertNotNil(cURLDesc.range(of: "-H \"X-Custom-Header: {\\\"key\\\": \\\"value\\\"}\""))
    }

    func test_cURLRequestPOSTDescription() {
        let newClient = HTTPClient(baseURL: nil)

        let url = URL(string: "http://127.0.0.1:8081/initial")!
        let req = HTTPRequest {
            $0.url = url
            $0.method = .post
            $0.headers = .init(headers: [
                .init(name: "X-Custom-Header", value: "{\"key\": \"value\"}")
            ])
        }

        let cURLDesc = req.cURLDescription(whenIn: newClient)
        let components = cURLCommandComponents(from: cURLDesc)

        // Then
        XCTAssertEqual(components[0..<3], ["$", "curl", "-v"])
        XCTAssertEqual(components[3..<5], ["-X", "POST"])
        XCTAssertEqual(components.last, "\"\(url)\"")
    }
    
    func test_cURLRequestPOSTRequestWithJSONParameters() throws {
        let newClient = HTTPClient(baseURL: nil)
        newClient.headers = .init()

        let url = URL(string: "http://127.0.0.1:8081/initial")!
        let req = try HTTPRequest {
            $0.url = url
            $0.method = .post
            $0.headers = .init(headers: [
                .contentType(.json)
            ])
            $0.body = try .json( ["foo": "bar",
                                  "fo\"o": "b\"ar",
                                  "f'oo": "ba'r"])
        }

        let cURLDesc = req.cURLDescription(whenIn: newClient)
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
    
    func test_POSTRequestWithCookieCURLDescription() {
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
        

        let cURLDesc = req.cURLDescription(whenIn: newClient)
        let components = cURLCommandComponents(from: cURLDesc)

        XCTAssertEqual(components[0..<3], ["$", "curl", "-v"])
        XCTAssertEqual(components[3..<5], ["-X", "POST"])
        XCTAssertEqual(components.last, "\"\(url)\"")
        XCTAssertEqual(components[5..<6], ["-b"])
    }
    
    public func test_urlSessionBasedOnTransferModeLarge() throws {
        let newClient = HTTPClient(baseURL: nil)

        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8081/initial")!
            $0.transferMode = .largeData
        }
        
        let sessionRequest = try req.urlSessionTask(inClient: newClient)
        XCTAssertNotNil(sessionRequest as? URLSessionDownloadTask)
    }
    
    public func test_urlSessionBasedOnTransferModeDefault() throws {
        let newClient = HTTPClient(baseURL: nil)

        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8081/initial")!
            $0.transferMode = .default
        }
        
        let sessionRequest = try req.urlSessionTask(inClient: newClient)
        XCTAssertNotNil(sessionRequest as? URLSessionDataTask)
    }
    
    func test_dataIsProperlyEncodedAndProperContentTypeIsSet() throws {
        let newClient = HTTPClient(baseURL: nil)

        let req = try HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8081/initial")!
            $0.body = try .json(TestParameters.default)
        }

        let request = try req.urlRequest(inClient: newClient)

        XCTAssertEqual(request.headers["Content-Type"], "application/json")
        XCTAssertEqual(request.httpBody?.asString, "{\"property\":\"property\"}")
    }
    
    func test_queryIsBodyEncodedAndProperContentTypeIsSetForPOSTRequest() throws {
        let newClient = HTTPClient(baseURL: nil)

        let req = try HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8081/initial")!
            $0.body = try .form(object: TestParameters.default)
        }

        let request = try req.urlRequest(inClient: newClient)

        // Then
        XCTAssertEqual(request.headers["Content-Type"], "application/x-www-form-urlencoded; charset=utf-8")
        XCTAssertEqual(request.httpBody?.asString, "property=property")
    }
    
    func test_encoderCanBeCustomized() throws {
        let newClient = HTTPClient(baseURL: nil)

        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8081/initial")!
            $0.add(parameters: ["bool": true])
        }

        let request = try req.urlRequest(inClient: newClient)
        
        // Then
        let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
        XCTAssertEqual(components?.percentEncodedQuery, "bool=true")
    }

    func test_encoderCanEncodeDecimalWithHighPrecision() throws {
        let newClient = HTTPClient(baseURL: nil)

        let req = HTTPRequest {
            $0.url = URL(string: "http://127.0.0.1:8081/initial")!
            $0.add(parameters: ["a": 1.123456])
        }

        let request = try req.urlRequest(inClient: newClient)
        
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
        let redirectStub = HTTPStubRequest().match(urlRegex: "/login").stub(method: .get, redirectsTo: redirectURL)
        HTTPStubber.shared.add(stub: redirectStub)
        
        // Create final URL
        let stubRedirect = HTTPStubRequest().match(urlRegex: "/redirected").stub(for: .get) { response in
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
        let result = try await req.fetch(newClient)
        XCTAssertEqual(result.statusCode, .ok)
    }
    
    func test_uriTemplateInitialization() async throws {
        let newClient = HTTPClient(baseURL: nil)
        
        let req = try HTTPRequest(URI: "https://jsonplaceholder.typicode.com/posts/{postId}",
                                  variables: ["postId": 1])
        let result = try await req.fetch(newClient)
        XCTAssertEqual(result.statusCode, .ok)
    }
    
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
