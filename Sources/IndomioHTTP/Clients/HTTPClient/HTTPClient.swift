//
//  IndomioHTTP
//
//  Created by the Mobile Team @ ImmobiliareLabs
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Copyright ©2021 Immobiliare.it SpA. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

public class HTTPClient: NSObject, HTTPClientProtocol {
    
    // MARK: - Public Properties
    
    /// Shared client for http request.
    public static let shared = HTTPClient()
    
    /// Delegate of the client.
    public var delegate: HTTPClientDelegate?
    
    /// Base URL.
    public var baseURL: String
    
    /// Service's URLSession instance to use.
    public var session: URLSession!
    
    /// Headers which are part of each request made using the client.
    public var headers = HTTPHeaders.default
    
    /// Security settings.
    public var security: HTTPSecurityProtocol?
    
    /// Follow or not redirects. By default the value is `follow` which uses
    /// the new proposed redirection by copying the original HTTPMethod, Body and Headers.
    ///
    /// You can further customize and alter the behaviour per single request by implementing
    /// the `HTTPClientDelegate`'s `client(:willPerformRedirect:response:newRequest:)`
    /// function.
    public var followRedirectsMode: HTTPRedirectMode = .follow
    
    /// Event monitor.
    public private(set) var eventMonitor: HTTPClientEventMonitor!
    
    /// Timeout interval for requests. Defaults to `60` seconds.
    /// Requests may override this behaviour.
    public var timeout: TimeInterval = 60
    
    /// Validators for response. Values are executed in order.
    public var validators: [HTTPResponseValidatorProtocol] = [
        HTTPDefaultValidator() // standard validator for http responses
    ]
        
    /// The cache policy for the request. Defaults to `.useProtocolCachePolicy`.
    /// Requests may override this behaviour.
    public var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    
    // MARK: - Initialization

    
    /// Initialize a new HTTP client with given `URLSessionConfiguration` instance.
    ///
    ///
    /// - Parameters:
    ///   - baseURL: base URL.
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
    public init(baseURL: String = "", configuration: URLSessionConfiguration = .default) {
        self.baseURL = baseURL
        super.init()
        
        self.eventMonitor = HTTPClientEventMonitor(client: self)
        self.session = URLSession(configuration: configuration, delegate: eventMonitor, delegateQueue: nil)
    }
    
    // MARK: - Public Functions
    
    /// Execute the request immediately.
    ///
    /// - Parameter request: request.
    /// - Returns: the request itself
    @discardableResult
    public func execute(request: HTTPRequestProtocol) -> HTTPRequestProtocol {
        do {
            let task = try createTask(for: request) // create the URLRequest and associated URLSessionTask to execute
            
            delegate?.client(self, didEnqueue: (request, task))
            eventMonitor.addRequest(request, withTask: task) // add to monitor the response

            task.resume() // start it immediately
            delegate?.client(self, didExecute: (request, task))
        } catch {
            // Something went wrong building request, avoid adding operation and dispatch the message
            let response = HTTPRawResponse(error: .failedBuildingURLRequest, forRequest: request)
            request.receiveHTTPResponse(response, client: self)
        }
        
        return request
    }
    
    /// Execute the request synchronously.
    ///
    /// - Parameter request: request.
    /// - Returns: HTTPRawResponse
    public func executeSync(request: HTTPRequestProtocol) -> HTTPResponseProtocol {
       let sem = DispatchSemaphore(value: 0)

        var rawResponse: HTTPResponseProtocol!
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }

            request.onRawResponse(queue: .main) { response in
                rawResponse = response
                sem.signal()
            }
            self.execute(request: request)
        }
        _ = sem.wait(timeout: .now() + 30)
        return rawResponse
    }
    
}

// MARK: - HTTPClient Extensions

extension HTTPClient {
    
    /// Add new validator function at the end of the list of validators of the client.
    ///
    /// - Parameters:
    ///   - name: name of the validator (used only for your own needs, library will not use it).
    ///   - onTop: add validator at the top of the validators list. It will be executed as first validator.
    ///   - handler: handler function.
    /// - Returns: Self
    public func addValidator(name: String? = nil, onTop: Bool = false,
                             _ handler: @escaping HTTPCustomValidator.Handler) -> Self {
        let validator = HTTPCustomValidator(name: name, handler)
        
        if onTop {
            validators.insert(validator, at: 0)
        } else {
            validators.append(validator)
        }
        return self
    }
    
}
