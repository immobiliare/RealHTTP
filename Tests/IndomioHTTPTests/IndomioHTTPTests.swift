    import XCTest
    @testable import IndomioHTTP

    final class IndomioNetworkTests: XCTestCase {


        func testExample() {
            // This is an example of a functional test case.
            // Use XCTAssert and related functions to verify your tests produce the correct
            // results.

            let client = HTTPClient(baseURL: "http://sp-ws-app-imm-develop.kube.dev.rm.ns.farm:80")
            
            LoginOp(username: "ciao", pwd: "bello").request.run(in: client)
            
            
        }
    }

    
    public struct Utente: HTTPDataDecodable, Decodable {
        var nome: String?
        var cognome: String?
    }
    
    public class LoginOp {
        public var username: String
        public var password: String
        
        public lazy var request: HTTPRequest<Utente, Error> = {
            var req = HTTPRequest<Utente,Error>(method: .post, route: "")
            return req
        }()
        
        public init(username: String, pwd: String) {
            self.username = username
            self.password = pwd
        }
        
    }
