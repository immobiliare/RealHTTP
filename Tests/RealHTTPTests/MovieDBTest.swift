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

public class MovieDBTest: XCTestCase {
    
    /// The shared client with their settings.
    private lazy var client: HTTPClient = {
        client = HTTPClient(baseURL: "https://api.themoviedb.org/3")
        // it will happens value to each call.
        client.queryParams = [
            .init(name: "api_key", value: "<API_TEST>"),
            .init(name: "language", value: "IT-it")
        ]
        return client
    }()
    
    /*
    /// Get the ranking for each category.
    func test_getRankingInAllCategories() async throws {
        let region: Rankings.List.Region = .Italy
        
        for category in Rankings.List.Category.allCases {
            print("Getting \(category.rawValue)...")
            let page = try await client.fetch(Rankings.List(category: .upcoming, region: region))
            print("\(page.results.count) movies in \(category.rawValue) of \(region.rawValue)")
        }
    }
    
    /// Search for a movie.
    func test_searchMovie() async throws {
        let data = try await client.fetch(Movies.Search("Godfather", year: 1972))
        print("\(data.results.count) movies found")
    }
    */
}

// MARK: - RequestConvertible

/// APIResourceConvertible is a protocol which describe the result
/// of a service with their expected output object and the function
/// which generate a valid executable request.
public protocol APIResourceConvertible {
    associatedtype Result: Decodable
    func request() -> HTTPRequest
}


public extension HTTPClient {
    
    /// Execute async fetch of a APIResourceConvertible resource.
    /// - Parameter convertible: object to execute.
    /// - Returns: Type-safe output described by the protocol.
    func fetch<T: APIResourceConvertible>(_ convertible: T) async throws -> T.Result {
        let result = try await fetch(convertible.request())
        return try result.decode(T.Result.self)
    }
    
}

public enum Rankings {}
public enum Movies {}

// MARK: - Search Movies Resource

public extension Movies {
    
    struct Search: APIResourceConvertible {
        public typealias Result = MoviesPage
        
        var query: String
        var includeAdult: Bool = false
        var year: Int?
        
        public init(_ query: String, year: Int? = nil) {
            self.query = query
            self.year = year
        }
        
        public func request() -> HTTPRequest {
            HTTPRequest {
                $0.method = .get
                $0.path = "/search/movie"
                $0.addQueryParameter(name: "query", value: query)
                $0.addQueryParameter(name: "include_adult", value: String(includeAdult))
                if let year = year {
                    $0.addQueryParameter(name: "year", value: String(year))
                }
            }
        }
    }
    
}

// MARK: - Ranking Resource

public extension Rankings {
    
    struct List: APIResourceConvertible {
        public typealias Result = MoviesPage
        
        public enum Category: String, CaseIterable {
            case upcoming
            case popular
            case topRated = "top_rated"
        }
        
        public enum Region: String {
            case Italy = "IT"
            case USA = "US"
        }
        
        public var category: Category
        public var region: Region
        public var page = 1
        
        public func request() -> HTTPRequest {
            HTTPRequest {
                $0.method = .get
                $0.path = "/movie/\(category.rawValue)"
                $0.addQueryParameter(name: "region", value: region.rawValue)
                $0.addQueryParameter(name: "page", value: String(page))
            }
        }
    }
    
}

// MARK: - MoviesPage

/// This describe the standard output for movies for TheMovieDB API Service.
public struct MoviesPage: Codable {
    var results: [Movie]
    var page: Int
    var totalPages: Int
    var totalResults: Int
    
    private enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

// MARK: - Movie

/// A single movie with their most important properties.
public struct Movie: Codable {
    var title: String?
    var id: Int
    
    private enum CodingKeys: String, CodingKey {
        case title, id
    }
}
