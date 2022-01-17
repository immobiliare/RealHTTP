import XCTest
@testable import RealHTTP

public struct User: Decodable {
    var username: String
}

final class RealHTTPTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.

        let expectation = XCTestExpectation(description: "Chops the vegetables")

        Task {
            let req = try HTTPRequest {
                $0.timeout = 5
                //$0.body = try .json(["c" : "b"])
                $0.scheme = .http
                $0.host = "httpbin.org"
                $0.path = "/get"
                $0.method = .get
                //$0.addQueryParameter(name: "p", value: "t")
            }
                
                //.fetch().decode(User.self)
            
            let user = try await req.fetch(HTTPClient.shared)
         
            print("ok")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1000)

        
    }
}
