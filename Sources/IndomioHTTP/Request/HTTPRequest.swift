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
import Combine

open class HTTPRequest<Object: HTTPDataDecodable>: HTTPRequestProtocol, BuilderRepresentable {
    public typealias HTTPRequestResult = Result<Object, Error>
    public typealias ResultCallback = ((HTTPRequestResult) -> Void)

    // MARK: - Public Properties
    
    /// Current state of the request.
    public private(set) var state: HTTPRequestState = .pending

    /// Keep the response received for this request.
    /// It's `nil` until the state of the request is `finished`.
    public private(set) var response: HTTPRawResponse?
            
    /// Route to the endpoint.
    open var route: String

    /// Number of retries for this request. By default is set to `0` which means
    /// no retries are executed.
    open var maxRetries: Int = 0
    
    /// Timeout interval.
    open var timeout: TimeInterval?
    
    /// HTTP Method for request.
    open var method: HTTPMethod
    
    /// Headers to send along the request.
    open var headers = HTTPHeaders()
    
    /// Query string parameters which are set with the full url of the request.
    open var queryParameters: URLParametersData?
    
    /// Body content of the request.
    open var content: HTTPRequestEncodableData?
    
    /// Cache policy.
    open var cachePolicy: URLRequest.CachePolicy?
    
    /// Request modifier callback.
    open var urlRequestModifier: HTTPURLRequestModifierCallback?
        
    /// The current result of the request. If not executed yet it's `nil`.
    public var result: HTTPRequestResult? {
        stateQueue.sync {
            return _result
        }
    }
    
    /// Thread safe property which return if the promise is currently in a `pending` or `executing` state.
    /// A pending promise it's a promise which is not resolved yet.
    public var isPending: Bool {
        return stateQueue.sync {
            return state == .pending || state == .executing
        }
    }
    
    // MARK: - Private Properties
    
    /// Inner storage of the result.
    private var _result: HTTPRequestResult?
    private var _rawResult: HTTPRawResponse?
    
    /// Registered callbacks
    private var resultCallback: (queue: DispatchQueue?, callback: ResultCallback)?
    private var rawResultCallback: (queue: DispatchQueue?, callback: DataResultCallback)?

    /// Sync queue.
    public let stateQueue = DispatchQueue(label: "com.indomio-http.request.state")
    
    // MARK: - Initialization
    
    /// Initialize a new request.
    ///
    /// - Parameters:
    ///   - method: method for http.
    ///   - route: route name.
    required public init(method: HTTPMethod = .get, route: String = "") {
        self.method = method
        self.route = route
    }
    
    // MARK: - Execute Request

    /// Run the request into the destination client.
    ///
    /// - Parameter client: client instance.
    /// - Throws: throw an exception if something went wrong.
    /// - Returns: Self
    public func run(in client: HTTPClient) -> Self {
        guard isPending else {
            return self // already started
        }
        
        changeState(.executing)
        client.execute(request: self)
        return self
    }
    
    // MARK: - Private Functions
    
    /// Sync change the state of the request.
    ///
    /// - Parameter newState: new state to set.
    private func changeState(_ newState: HTTPRequestState) {
        stateQueue.sync {
            state = newState
            
            if newState == .finished {
                dispatchEvents()
            }
        }
    }
    
    /// Dispatch events call registered events.
    private func dispatchEvents() {
        guard state == .finished else {
            return
        }
        
        // Raw Response
        if let rawResult = _rawResult, let rawResultCallback = self.rawResultCallback  {
            if let queue = rawResultCallback.queue {
                queue.async {
                    rawResultCallback.callback(rawResult)
                }
            } else {
                rawResultCallback.callback(rawResult)
            }
        }
        
        // Decoded Response
        if let result = _result, let resultCallback = self.resultCallback {
            if let queue = resultCallback.queue {
                queue.async {
                    resultCallback.callback(result)
                }
            } else {
                resultCallback.callback(result)
            }
        }
    }
    
    /// link with the raw response.
    ///
    /// - Parameter callback: callback.
    /// - Returns: Self
    @discardableResult
    public func response(in queue: DispatchQueue? = .main, _ callback: @escaping ResultCallback) -> Self {
        stateQueue.sync {
            resultCallback = (queue, callback)
            dispatchEvents()
        }
        return self
    }
    
    /// Attempt to execute the request to get raw response data.
    ///
    /// - Parameter callback: callback.
    /// - Returns: Self
    @discardableResult
    public func rawResponse(in queue: DispatchQueue? = .main, _ callback: @escaping DataResultCallback) -> Self {
        stateQueue.sync {
            rawResultCallback = (queue, callback)
            dispatchEvents()
        }
        return self
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
    
    /// Set the route of the request.
    ///
    /// - Parameter route: route.
    /// - Returns: Self
    public func route(_ route: String) -> Self {
        self.route = route
        return self
    }
    
    /// Set the retry attempts for request.
    ///
    /// - Parameter attempts: attempts.
    /// - Returns: Self
    public func retry(_ attempts: Int) -> Self {
        self.maxRetries = attempts
        return self
    }
    
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
    /// - Parameter timeout: timeout interval in seconds.
    /// - Returns: Self
    public func timeout(_ timeout: TimeInterval) -> Self {
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
    public func query(_ queryParams: [String: AnyObject]) -> Self {
        self.queryParameters = URLParametersData(in: .queryString, parameters: queryParams)
        return self
    }
    
    /// Set the body of the request to the parameters encoded and x-www-formurlencoded format.
    ///
    /// - Parameter parameters: parameters to set.
    /// - Returns: Self
    public func formURLEncoded(_ parameters: [String: AnyObject]) -> Self {
        self.content = URLParametersData(in: .httpBody, parameters: parameters)
        return self
    }
    
    // MARK: - Private Functions
    
    /// Build the request when running in a given client.
    ///
    /// - Parameter client: client where the request is running into.
    /// - Throws: throw an exception if request building process did fails.
    /// - Returns: URLRequest
    open func urlRequest(in client: HTTPClient) throws -> URLRequest {
        // Create the full URL of the request.
        let fullURLString = (client.baseURL + route)
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
    
    public func receiveResponse(_ response: HTTPRawResponse, client: HTTPClient) {
        guard isPending else {
            return // ignore any further data when request is completed yet.
        }
        
        do {
            print(response.data?.jsonString())
            let decodedObj = try Object.decode(response)
            print(decodedObj)
        } catch {
            fatalError()
        }
    
        
        stateQueue.sync {
            self.state = .finished
            self._rawResult = response
            dispatchEvents()
        }
    }
    
}
