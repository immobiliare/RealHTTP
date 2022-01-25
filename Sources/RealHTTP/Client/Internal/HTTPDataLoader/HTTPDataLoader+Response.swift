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

/// This is the object produced by a data loader as response for a fetch request.
/// It's used internally and should be not exposed.
internal class HTTPDataLoaderResponse {
    public typealias Completion = ((HTTPResponse) -> Void)

    // MARK: - Properties
    
    /// Downloaded data.
    var data: Data?
    
    /// Downloaded data URL for `largeData` transfer mode.
    var dataFileURL: URL?
    
    /// Metrics stats.
    var metrics: URLSessionTaskMetrics?
    
    /// Error occurred.
    var error: Error?
    
    /// response received from fetch.
    var urlResponse: URLResponse?
    
    /// Completion callback called by the data loader in order to incapsulate the async/await logic.
    var completion: Completion
    
    /// Parent request.
    var request: HTTPRequest
    
    /// Report the URLRequests executed by the client.
    /// - original: The original request object passed when the task was created.
    /// - current:  The URL request object currently being handled by the task.
    ///             This value is typically the same as the initial request (`original`)
    ///             except when the server has responded to the initial request with a
    ///             redirect to a different URL.
    var urlRequests: (original: URLRequest?, current: URLRequest?) = (nil, nil)
    
    // MARK: - Initialization
    
    /// Initialize a new response.
    ///
    /// - Parameters:
    ///   - request: request.
    ///   - completion: completion block.
    init(request: HTTPRequest, completion: @escaping Completion) {
        self.request = request
        self.completion = completion
    }
    
    // MARK: - Methods
    
    /// Append data to the response.
    ///
    /// - Parameter newData: new data to append.
    func appendData(_ newData: Data) {
        if data == nil {
            data = newData
        } else {
            data?.append(newData)
        }
    }
    
}
