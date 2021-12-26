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

        
        Task {
            let req = try HTTPRequest {
                $0.timeout = 5
                $0.body = try .json(["c" : "b"])
                $0.scheme = .https
                $0.host = "apple.com"
                $0.addQueryParameter(name: "p", value: "t")
            }
                
                //.fetch().decode(User.self)
            
            let user = try await RealHTTP.fetch(req).decode(User.self)
            
            print(user.debugDescription)
        }
        
    }
}
