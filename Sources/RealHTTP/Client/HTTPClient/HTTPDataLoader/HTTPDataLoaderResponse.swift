//
//  RealHTTP
//
//  Created by the Mobile Team @ ImmobiliareLabs
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Copyright ©2021 Immobiliare.it SpA. All rights reserved.
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
