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

internal class HTTPRequestOperation : Operation {
    
    // MARK: - Private Properties
    
    private var task : URLSessionTask!
    private var request: HTTPRequestProtocol
    private weak var client: HTTPClientQueue?
    
    // default state is ready (when the operation is created)
    private var state : OperationState = .ready {
        willSet {
            self.willChangeValue(forKey: "isExecuting")
            self.willChangeValue(forKey: "isFinished")
        }
        
        didSet {
            self.didChangeValue(forKey: "isExecuting")
            self.didChangeValue(forKey: "isFinished")
        }
    }
    
    override var isReady: Bool { return state == .ready }
    override var isExecuting: Bool { return state == .executing }
    override var isFinished: Bool { return state == .finished }
  
    // MARK: - Initialization
    
    init(client: HTTPClientQueue, request: HTTPRequestProtocol) {
        self.client = client
        self.request = request
        
        super.init()
        
        do {
            let urlRequest = try request.urlRequest(in: client)
            self.task = client.session.dataTask(with: urlRequest, completionHandler: { [weak self] data, urlResponse, error in
                guard let self = self else { return }
                
                // Parse the response and create the object which contains all the datas.
                var response = HTTPRawResponse(request: request,
                                               urlRequest: urlRequest,
                                               client: client,
                                               response: urlResponse,
                                               data: data,
                                               error: error)
                self.didCompleteRequest(request, response: &response)
            })
        } catch {
            didFailBuildingURLRequestFor(request, error: error)
        }
    }
    
    // MARK: - Override
    
    override func start() {
        /// If the operation or queue got cancelled even
        /// before the operation has started, set the
        /// operation state to finished and return
        if self.isCancelled {
            state = .finished
            return
        }
        
        // set the state to executing
        state = .executing
        // start the downloading
        self.task.resume()
    }
    
    override func cancel() {
        super.cancel()
        
        // cancel the downloading
        self.task.cancel()
    }
    
    // MARK: - Private Functions
    
    private func didCompleteRequest(_ request: HTTPRequestProtocol, response: inout HTTPRawResponse) {
        defer {
            state = .finished
        }
        
        guard let client = self.client else {
            return
        }
        
        /// Set the operation state to finished once
        /// the download task is completed or have error.
        let validationAction = client.validate(response: response)
        switch validationAction {
        case .failWithError(let error):
            // Response validation failed with error, set the new error and forward it
            response.error = HTTPError(.invalidResponse, error: error)
            didCompleteRequest(request, response: &response)
            
        case .retryAfter(let altRequest):
            // Response validation failed, you can retry but we need to execute another call first.
            request.reset(retries: true)
            
            let altRequestOp = HTTPRequestOperation(client: client, request: altRequest)
            let newRequestOp = HTTPRequestOperation(client: client, request: request)
            newRequestOp.addDependency(altRequestOp)
            
            client.addOperation(altRequestOp, newRequestOp)
            
        case .retryIfPossible:
            request.currentRetry += 1
            
            guard request.currentRetry < request.maxRetries else {
                // Maximum number of retry attempts made.
                response.error = HTTPError(.maxRetryAttemptsReached)
                didCompleteRequest(request, response: response)
                return
            }
            
            // Reset the state and make another attempt
            request.reset(retries: false)
            let op = HTTPRequestOperation(client: client, request: request)
            client.addOperation(op)

        case .passed:
            // Passed, nothing to do
            didCompleteRequest(request, response: response)
            
        }
        
    }
    
    func didCompleteRequest(_ request: HTTPRequestProtocol, response: HTTPRawResponse) {
        request.receiveResponse(response, client: client!)
    }
    
    private func didFailBuildingURLRequestFor(_ request: HTTPRequestProtocol, error: Error) {
        defer {
            state = .finished
        }
        
        guard let client = self.client else {
            return
        }
    
        let error = HTTPError(.failedBuildingURLRequest, error: error)
        let response = HTTPRawResponse(request: request, urlRequest: nil, client: client, error: error)
        didCompleteRequest(request, response: response)
    }
    
}

// MARK: - OperationState

fileprivate extension HTTPRequestOperation {
    
    /// State of the operation.
    /// - `ready`: operation ready to be executed.
    /// - `executing`: operation is in progress.
    /// - `finished`: operation did complete.
    enum OperationState : Int {
        case ready
        case executing
        case finished
    }
    
}