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

// MARK: - HTTPRawRequest

// When you don't need to get a decoded object but you want to read the raw response
// you can use this typealias to skip the decode part and get the raw data coming from server.
public typealias HTTPRawRequest = HTTPRequest<HTTPRawResponse>

// MARK: - HTTPRequest (Decode)

/// Defines the generic request you can execute in a client.
open class HTTPRequest<Object: HTTPDecodableResponse>: HTTPRequestProtocol {
    public typealias HTTPRequestResult = Result<Object, HTTPError>
    public typealias ResultCallback = ((HTTPRequestResult) -> Void)
    public typealias ProgressCallback = ((HTTPProgress) -> Void)
    
    // MARK: - Public Properties
    
    /// An user info dictionary where you can add your own data.
    /// Initially only the `fingerprint` key is set with an unique id of the request.
    public var userInfo: [AnyHashable : Any] = [
        HTTPRequestUserInfoKeys.fingerprint: UUID().uuidString
    ]
    
    /// Current state of the request.
    public private(set) var state: HTTPRequestState = .pending

    /// Keep the response received for this request.
    /// It's `nil` until the state of the request is `finished`.
    public private(set) var response: HTTPRawResponse?
    
    /// It's marked when you call `cancel()` on a operation.
    public private(set) var isCancelled: Bool = false
    
    /// Associated task. It's valid when running on a client.
    public weak var task: URLSessionTask?

    /// Decoded object if any.
    /// It's thread safe.
    public var object: Object? {
        stateQueue.sync {
            switch responseResult {
            case .success(let obj): return obj
            default: return nil
            }
        }
    }
    
    /// Route to the endpoint.
    open var route: String

    /// Number of retries for this request. By default is set to `0` which means
    /// no retries are executed.
    open var maxRetries: Int = 0
    
    /// Current number of retry attempt done.
    /// NOTE: You should never modify it externally, it's managed by the `HTTPClient` instance.
    open var currentRetry: Int = 0
    
    /// Timeout interval.
    open var timeout: TimeInterval?
    
    /// HTTP Method for request.
    open var method: HTTPMethod
    
    /// Headers to send along the request.
    open var headers = HTTPHeaders()
    
    /// Security settings.
    open var security: HTTPSecurityProtocol?
    
    /// What kind of data we should expect.
    /// If you are creating a request for a small amount of data (ie RESTful calls) you can use
    /// `default`. Large data as binary downloads may be handled using `large` options which support
    /// resumable downloads and background downloads sessions.
    /// By default `default` is used.
    open var transferMode: HTTPTransferMode = .default
    
    /// If task is monitorable (`expectedDataType` is `large`) and data is available
    /// here you can found the latest progress stats.
    #if canImport(Combine)
    @Published public private(set) var progress: HTTPProgress?
    #else
    public private(set) var progress: HTTPProgress?
    #endif
    
    /// The default location of response data when using `large` `expectedDataType` and the engine
    /// is set to `URLDownloadTask`. It can be used to resume initiated downloads or to use the
    /// background session downloads. When `expectedDataType` is set to `default` this value is
    /// ignored (the response itself is kept in memory).
    open var resumeData: Data? {
        didSet {
            transferMode = (resumeData == nil ? .default : .largeData)
        }
    }
    
    /// Query string parameters which are set with the full url of the request.
    open var queryParameters: URLParametersData?
    
    /// Body content of the request.
    open var content: HTTPRequestEncodableData?
    
    /// Cache policy.
    open var cachePolicy: URLRequest.CachePolicy?
    
    /// Request modifier callback.
    /// You can implement your own logic to modify a generated `URLRequest` for the request
    /// running in a specified `HTTPClientProtocol` instance.
    open var urlRequestModifier: HTTPURLRequestModifierCallback?
        
    /// Thread safe property which return if the promise is currently in a `pending` or `executing` state.
    /// A pending promise it's a promise which is not resolved yet.
    public var isPending: Bool {
        return stateQueue.sync {
            return state == .pending || state == .executing
        }
    }
    
    /// Describe the priority of the operation.
    /// It may acts as a suggestion for HTTP/2 based services (priority frames / dependency weighting)
    /// for simple `HTTPClient` instances.
    /// In case of `HTTPQueueClient` it also act as priority level for queue concurrency.
    /// See the doc for more infos; by default is set to `.normal`.
    public var priority: HTTPRequestPriority = .normal
    
    // MARK: - Observers
    
    /// Registered callbacks for decoded object events.
    public private(set) var objectObservers = EventObserver<HTTPRequestResult>()
    
    /// Registered callbacks for raw data events.
    public private(set) var responseObservers = EventObserver<HTTPRawResponse>()
    
    /// Registered callbacks for download/upload progress events.
    public private(set) var progressObservers = EventObserver<HTTPProgress>()

    // MARK: - Private Properties
    
    /// Decoded object if any.
    private var responseResult: HTTPRequestResult?
    
    /// Sync queue.
   internal let stateQueue = DispatchQueue(label: "com.indomio-http.request.state")
    
    // MARK: - Initialization
    
    /// Initialize a new request.
    ///
    /// - Parameters:
    ///   - method: method for http.
    ///   - route: route name.
    required
    public init(_ method: HTTPMethod = .get, route: String = "") {
        self.method = method
        self.route = route
    }
    
    /// Initialize a new request with given URI template and variables.
    /// The `route` property will be assigned expanding the variables over the template
    /// according to the RFC6570 (<https://tools.ietf.org/html/rfc6570>) protocol.
    ///
    /// - Parameters:
    ///   - method: method of the http.
    ///   - template: URI template as specified by RFC6570.
    ///   - variables: variables to expand.
    required
    public init(_ method: HTTPMethod = .get, URI template: String, variables: [String: Any]) {
        self.method = method
        let template = URITemplate(template: template)
        self.route = template.expand(variables)
    }
    
    // MARK: - Execute Request
    
    /// Run request asynchrously in shared client.
    ///
    /// - Returns: Self
    @discardableResult
    public func run() -> Self {
        run(in: nil)
    }
    
    /// Run request synchroously in shared client.
    ///
    /// - Returns: HTTPRawResponse?
    public func runSync() -> HTTPRawResponse? {
        runSync(in: nil)
    }
    
    /// Run the request into the destination client.
    ///
    /// - Parameter client: client instance.
    /// - Throws: throw an exception if something went wrong.
    /// - Returns: Self
    @discardableResult
    public func run(in client: HTTPClientProtocol?) -> Self {
        guard isPending else {
            return self // already started
        }
        
        changeState(.executing)
        (client ?? HTTPClient.shared).execute(request: self)
        return self
    }
    
    /// Run the request into destination client synchrously.
    ///
    /// - Parameter client: client instance.
    /// - Returns: HTTPRawResponse?
    public func runSync(in client: HTTPClientProtocol?) -> HTTPRawResponse? {
        guard isPending else {
            return response // already started
        }
        
        changeState(.executing)
        return (client ?? HTTPClient.shared).executeSync(request: self)
    }
    
    // MARK: - Others
    
    /// Reset the state by removing any downloaded data and make
    /// the call as never executed. Usually it's used before
    /// making a retry attempt.
    public func reset(retries: Bool) {
        stateQueue.sync {
            guard state != .executing else {
                return
            }
            
            state = .pending
            
            if retries {
                currentRetry = 0
            }
            
            response = nil
            responseResult = nil
        }
    }
    
    /// Cancel a task. Task result in an error of type `cancelled`.
    /// - Parameters:
    ///   - byProducingResumeData:  pass `true` and if resume is supported `resumableData`
    ///                             of the response will contain data you can use to resume the call.
    ///   - callback: you can specify a callback to receive resumable data once available.
    public func cancel(byProducingResumeData: Bool = false, callback: ((Data?) -> Void)?) {
        stateQueue.sync { [weak self] in
            guard let self = self else { return }
            
            if !state.isFinished {
                // Mark as cancelled
                response = HTTPRawResponse(error: .cancelled, forRequest: self)
            }
            
            state = .cancelled
            
            if byProducingResumeData,
               let downloadTask = self.task as? URLSessionDownloadTask {
                // When supported cancel will produce resumable data you can use to recover it.
                downloadTask.cancel { [weak self] resumableData in
                    self?.response?.resumableData = resumableData
                    callback?(resumableData)
                }
            } else {
                // A simple cancel of the task
                self.task?.cancel()
            }
            
            if state.isFinished  {
                dispatchEvents()
            }
        }
    }
    
    /// Cancel a task. Task result in an error of type `cancelled`.
    ///
    /// - Parameter byProducingResumeData: pass `true` and if resume is supported `resumableData`
    ///                                    of the response will contain data you can use to resume the call.
    ///                                    NOTE: the resumable data may be produced later after the request is finished.
    ///                                    This because it's an async operation.
    public func cancel(byProducingResumeData: Bool = false) {
        cancel(byProducingResumeData: byProducingResumeData, callback: nil)
    }
    
    // MARK: - Private Functions
    
    /// Sync change the state of the request.
    ///
    /// - Parameter newState: new state to set.
    private func changeState(_ newState: HTTPRequestState) {
        stateQueue.sync {
            state = newState
        
            if newState.isFinished {
                dispatchEvents()
            }
        }
    }
    
    /// Dispatch events call registered events.
    internal func dispatchEvents() {
        guard state.isFinished else {
            return
        }
        
        // Raw Response
        if let rawResponse = self.response {
            responseObservers.callWithValue(rawResponse)
        }
        
        // Decoded Response
        if let result = responseResult {
            objectObservers.callWithValue(result)
        }
        
    }
    
}

// MARK: - HTTPRequest Configuration

extension HTTPRequest {
        
    /// Set the HTTP method for request.
    ///
    /// - Parameter httpMethod: method to use.
    /// - Returns: Self
    public func method(_ httpMethod: HTTPMethod) -> Self {
        self.method = httpMethod
        return self
    }
    
    /// Set the transfer mode of the data.
    /// You may want to set `.largeData` when you need to transfer much larger amounts
    /// of data from Data in memory, a file URL, or an InputStream.
    ///
    /// - Parameter transferMode: transfer mode; for small amount of data - typically JSON response, you can leave it to `default`.
    ///                           If you are moving large amount of data use `.largeData`.
    /// - Returns: Self
    public func mode(_ transferMode: HTTPTransferMode) -> Self {
        self.transferMode = transferMode
        return self
    }
    
    /// Set the maximum number of retries to made.
    /// By default is 0 which means any retry will be made in case of failure.
    ///
    /// - Parameter maxRetries: max retires.
    /// - Returns: Self
    public func maxRetries(_ maxRetries: Int) -> Self {
        self.maxRetries = maxRetries
        return self
    }
    
    /// Setup the security for this request.
    ///
    /// - Parameter security: security.
    /// - Returns: Self
    public func security(_ security: HTTPSecurityProtocol) -> Self {
        self.security = security
        return self
    }
    
    /// Set the route of the request.
    ///
    /// - Parameter route: route.
    /// - Returns: Self
    public func route(_ route: String) -> Self {
        self.route = route
        return self
    }
    
    /// Add/replace the header for the request.
    ///
    /// - Parameters:
    ///   - name: name of the field to set.
    ///   - value: value of the field.
    /// - Returns: Self
    public func header(_ name: HTTPHeaderField, _ value: String) -> Self {
        self.headers[name] = value
        return self
    }
    
    /// Set multiple headers.
    ///
    /// - Parameter headers: headers.
    /// - Returns: Self
    public func headers(_ builder: ((inout HTTPHeaders) -> Void)) -> Self {
        builder(&headers)
        return self
    }
    
    /// Set the request timeout interval.
    /// If not set the `HTTPClient`'s timeout where the instance is running will be used.
    /// - Parameter timeout: timeout interval in seconds, `nil` to ignore timeout.
    /// - Returns: Self
    public func timeout(_ timeout: TimeInterval?) -> Self {
        self.timeout = timeout
        return self
    }
    
    /// Set the content of the request to Multipart Form Data by passing a preconfigured MultipartForm object.
    /// Any previously set body is overriden.
    ///
    /// - Parameter form: form to set.
    /// - Returns: Self
    public func multipart(_ form: MultipartFormData) -> Self {
        self.content = form
        return self
    }
    
    /// Set the content of the request to a builder configuration for a MultipartForm.
    /// The object is created for you and you can configure the content of the form directly
    /// from the callback.
    ///
    /// - Parameters:
    ///   - boundary: boundary identifier; ignore parameters to automatically generate the boundary.
    ///   - builder: builder callback where you can configure the instance of the new MultipartForm created.
    /// - Returns: Self
    public func multipart(boundary: String? = nil, _ builder: ((inout MultipartFormData) -> Void)) -> Self {
        var multipartForm = MultipartFormData(boundary: boundary)
        builder(&multipartForm)
        self.content = multipartForm
        return self
    }
    
    /// Set the content of the request to a `Encodable` object.
    ///
    /// - Parameters:
    ///   - encoder: encoder used for serialization.
    ///   - params: parameters to set.
    /// - Returns: Self
    public func json<Object: Encodable>(encoder: JSONEncoder? = nil, _ object: Object) -> Self {
        self.content = EncodableJSON(encoder, object: object)
        return self
    }
    
    /// Set the content of the request to a JSON serializable object.
    /// - Parameters:
    ///   - options: options for writing content. By default it uses `.sortedKey` in order to produce the same
    ///              url every time and avoid problem with backend cache which depends by the same url every time.
    ///   - params: parameters list.
    /// - Returns: Self
    public func json(_ options: JSONSerialization.WritingOptions = [.sortedKeys], _ params: Any) -> Self {
        self.content = JSONData(params, options: options)
        return self
    }
    
    /// Set the query parameters for request.
    ///
    /// - Parameter queryParams: query parameters.
    /// - Returns: Self
    public func query(_ queryParams: [String: Any]) -> Self {
        self.queryParameters = URLParametersData(in: .queryString, parameters: queryParams)
        return self
    }
    
    /// Download large data file/resource with progress tracking.
    ///
    /// - Parameter fileURL: URL of the resource.
    /// - Returns: Self
    
    /// Download large data file/resource with progress tracking.
    ///
    /// - Parameters:
    ///   - url: URL of the resource to download.
    ///   - resumeData: pass a valid Data produced by resumable methods in order to resume download.
    /// - Returns: Self
    public func resourceAtURL(_ url: String, resumingWith resumeData: Data? = nil) -> Self {
        self.transferMode = .largeData
        self.resumeData = resumeData
        self.route = url
        return self
    }
    
    /// Set the encoding style for objects in query parameters.
    /// NOTE: You must have set the query parameters object first with `.queryParameters` or `query()` function
    /// otherwise the value will be empty.
    ///
    /// - Parameters:
    ///   - array: array encoding style.
    ///   - bool: bool encoding style.
    /// - Returns: Self
    public func queryEncodingStyle(array: URLParametersData.ArrayEncodingStyle = .withBrackets,
                                   bool: URLParametersData.BoolEncodingStyle = .asNumbers) -> Self {
        queryParameters?.arrayEncoding = array
        queryParameters?.boolEncoding = bool
        return self
    }
    
    /// Set the body of the request to the parameters encoded and x-www-formurlencoded format.
    ///
    /// - Parameter parameters: parameters to set.
    /// - Returns: Self
    public func formURLEncoded(_ parameters: HTTPRequestParametersDict?) -> Self {
        self.content = URLParametersData(in: .httpBody, parameters: parameters)
        return self
    }
    
    /// Allows you to transfer binary data as body content of the request.
    ///
    /// - Parameters:
    ///   - data: data to set.
    ///   - transfer: mode of transfer; use `largeData` if you plan to transfer/receive a significant amount of data.
    /// - Returns: Self
    public func data(_ data: Data, transferAs mode: HTTPTransferMode = .largeData) -> Self {
        self.transferMode = mode
        self.content = data
        return self
    }
    
    /// Allows you to transfer the content of file as body of the request.
    /// Content is read and placed in memory; if you plan to send large amount of data try stream instead.
    ///
    /// - Parameter fileURL: url of the local file.
    /// - Returns: Self
    public func file(_ fileURL: URL) -> Self {
        self.content = Data.fromURL(fileURL)
        self.transferMode = .largeData
        return self
    }
    
    /// Initiate a stream upload for a local file.
    /// Content will be set to the stream.
    ///
    /// - Parameter fileURL: local file URL.
    /// - Returns: Self
    public func stream(fileURL: URL) -> Self {
        self.content = HTTPStreamContent(fileURL: fileURL)
        self.transferMode = .largeData
        return self
    }
    
    /// Initiate a stream upload for data content.
    /// Content will be set to the stream.
    ///
    /// - Parameter data: data content.
    /// - Returns: Self
    public func stream(data: Data) -> Self {
        self.content = HTTPStreamContent(data: data)
        self.transferMode = .largeData
        return self
    }
    
    // MARK: - Private Functions
    
    /// Build the request when running in a given client.
    ///
    /// - Parameter client: client where the request is running into.
    /// - Throws: throw an exception if request building process did fails.
    /// - Returns: URLRequest
    open func urlRequest(in client: HTTPClientProtocol) throws -> URLRequest {
        // Create the full URL of the request.
        // If route contains an absolute path avoid to compose it with the client's based URL but
        // deals it as absolute string to set.
        let fullURLString = (!route.isRelative ? route : (client.baseURL + route))
        guard let fullURL = URL(string: fullURLString) else {
            throw HTTPError(.invalidURL(fullURLString)) // failed to produce a valid url
        }
        
        // Setup the new URLRequest instance
        let cachePolicy = cachePolicy ?? client.cachePolicy
        let timeout = timeout ?? client.timeout
        let headers = (client.headers + headers)
        
        var urlRequest = try URLRequest(url: fullURL,
                                        method: method,
                                        cachePolicy: cachePolicy,
                                        timeout: timeout,
                                        headers: headers)
        
        // Encode query string parameters
        try queryParameters?.encodeParametersIn(request: &urlRequest)
        // Encode the body
        try content?.encodeParametersIn(request: &urlRequest)
        
        // Apply modifier if set
        try urlRequestModifier?(&urlRequest)

        return urlRequest
    }
    
    public func receiveHTTPResponse(_ response: HTTPRawResponse, client: HTTPClientProtocol) {
        guard isPending else {
            return // ignore any further data when request is completed yet.
        }

        self.task = nil // reset the task

        // Attempt to decode the object.
        let decodedObj = Object.decode(response)
        
        stateQueue.sync {
            self.state = .finished
            // Keep in cache our data decoded and raw
            self.response = response
            self.responseResult = decodedObj

            if case .failure(let decodeError) = decodedObj {
                self.response?.error = HTTPError(.objectDecodeFailed, error: decodeError)
            }

            dispatchEvents()
        }
        
    }
    
    public func receiveHTTPProgress(_ progress: HTTPProgress) {
        self.progress = progress
        
        progressObservers.callWithValue(progress)
    }
    
}

// MARK: - EventObserver

/// Keep a list of all observers registered for a particular callback.
public class EventObserver<Object> {
    public typealias Observer = ((Object) -> Void)
    
    // MARK: - Private Properties
    
    private var nextToken: UInt64 = 0
    private var observersMap = [UInt64: Observer]()
    private var stateQueue = DispatchQueue(label: "com.eventobserver.\(UUID().uuidString)")
    
    // MARK: - Public Properties
    
    /// List of active observers.
    public var observers: [Observer] {
        stateQueue.sync {
            Array(observersMap.values)
        }
    }
    
    /// Add a new observer and return the associated token identifier.
    ///
    /// - Parameter observer: observer to add.
    /// - Returns: UInt64
    public func add(_ observer: @escaping Observer) -> UInt64 {
        stateQueue.sync {
            nextToken = nextToken.addingReportingOverflow(1).partialValue
            observersMap[nextToken] = observer
            return nextToken
        }
    }
    
    /// Remove observer with given token.
    ///
    /// - Parameter token: token.
    public func remove(_ token: UInt64) {
        stateQueue.sync {
            _ = observersMap.removeValue(forKey: token)
        }
    }
    
    /// Remove all observers.
    public func removeAll() {
        stateQueue.sync {
            observersMap.removeAll()
        }
    }
    
    // MARK: - Private Functions
    
    /// Call all observers with given value.
    ///
    /// - Parameter object: value to dispatch.
    internal func callWithValue(_ object: Object) {
        for observer in observers {
            observer(object)
        }
    }
    
}
