//
//  IndomioNetwork
//
//  Created by the Mobile Team @ ImmobiliareLabs
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Copyright ©2021 Immobiliare.it SpA. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

/// It's like `HTTPClient` but it maintain a queue of requests and
/// manage the maximum simultaneous requests you can execute
/// automatically.
/// You can use it when you need more control about the requests.
public class HTTPClientQueue: HTTPClient {
    
    // MARK: - Public Properties
    
    /// Maximum number of rimultaneous requests.
    public var maxSimultaneousRequest: Int {
        didSet {
            operationQueue.maxConcurrentOperationCount = maxSimultaneousRequest
        }
    }
    
    /// Get the number of operations in queue.
    public var countRequests: Int {
        operationQueue.operationCount
    }
    
    /// The operation queue.
    private var operationQueue = OperationQueue()
    
    
    // MARK: - Initialization

    /// Initialize a new HTTP client which manage a queue of operations with given `URLSessionConfiguration` instance.
    ///
    /// - Parameters:
    ///   - maxSimultaneousRequest: number of simultaneous requests to execute.
    ///   - baseURL: base url.
    ///   - configuration: `URLSession` configuration. The available types are `default`,
    ///                    `ephemeral` and `background`, if you don't provide any or don't have
    ///                     special needs then Default will be used.
    ///
    ///                     - `default`: uses a persistent disk-based cache (except when the result is downloaded to a file)
    ///                     and stores credentials in the user’s keychain.
    ///                     It also stores cookies (by default) in the same shared cookie store as the
    ///                     NSURLConnection and NSURLDownload classes.
    ///                     - `ephemeral`: similar to a default session configuration object except that
    ///                     the corresponding session object does not store caches,
    ///                     credential stores, or any session-related data to disk. Instead,
    ///                     session-related data is stored in RAM.
    ///                     - `background`: suitable for transferring data files while the app runs in the background.
    ///                     A session configured with this object hands control of the transfers over to the system,
    ///                     which handles the transfers in a separate process.
    ///                     In iOS, this configuration makes it possible for transfers to continue even when
    ///                     the app itself is suspended or terminated.
    public init(maxSimultaneousRequest: Int = 5,
                baseURL: String,
                configuration: URLSessionConfiguration = .default) {
        
        self.maxSimultaneousRequest = maxSimultaneousRequest
        super.init(baseURL: baseURL, configuration: configuration)
    }
    
    // MARK: - Public Functions
    
    /// Put in queue an operation.
    /// Operation may be not executed immediately but following the operations
    /// enqueued in client.
    ///
    /// - Parameter request: request
    /// - Returns: the request itself
    public override func execute(request: HTTPRequestProtocol) -> HTTPRequestProtocol {
        do {
            let task = try createTask(for: request) // build URLRequest along with the URLSessionTask to execute
            let operation = HTTPRequestOperation(task: task) // create a container for the task
            
            eventMonitor.addRequest(request, withTask: task) // monitor response
            addOperations(operation) // put in queue the operation
        } catch {
            // Something went wrong building request, avoid adding operation and dispatch the message
            let response = HTTPRawResponse(error: .failedBuildingURLRequest, forRequest: request)
            request.receiveHTTPResponse(response, client: self)
        }
        
        return request
    }
    
    // MARK: - Private Functions
    
    /// Add operations to the queue.
    ///
    /// - Parameter operations: operations to add.
    internal func addOperations(_ operations: HTTPRequestOperation...) {
        operations.forEach {
            operationQueue.addOperation($0)
        }
    }
    
    internal func operationForTask(_ task: URLSessionTask) -> HTTPRequestOperation? {
        operationQueue.operations.first {
            ($0 as? HTTPRequestOperation)?.task == task
        } as? HTTPRequestOperation
    }
    
}
