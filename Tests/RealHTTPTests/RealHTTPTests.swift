import XCTest
@testable import RealHTTP

extension Data: HTTPDecodableResponse {
    
}

final class RealHTTPTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.

        
        Task {
            let result = try await HTTPRequest<Data> {
                $0.timeout = 5
                $0.body = try .json(["c" : "b"])
                $0.scheme = .https
                $0.host = "apple.com"
                $0.addQueryParameter(name: "p", value: "t")
            }.execute()
            
            
        }
        
    }
}
