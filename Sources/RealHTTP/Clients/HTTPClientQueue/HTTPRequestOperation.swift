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

/// This class is used to enqueue a `HTTPRequestProtocol` inside an operation queue
/// and it's used by the `HTTPClientQueue`. You should never need to instantiate this
/// class but it will be created automatically for you when client execute a new request.
internal class HTTPRequestOperation : Operation {
    
    // MARK: - Private Properties
    
    /// Associated session task. It will be executed (via `resume()`) when
    /// operation will be picked and started.
    internal private(set) var task : URLSessionTask!
        
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
    
    internal init(task: URLSessionTask) {
        self.task = task
        
        super.init()
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
        
        state = .executing // set the state to executing
        task.resume() // start the downloading
    }
    
    override func cancel() {
        super.cancel()
        
        task.cancel() // cancel the downloading
    }
    
    
    func end() {
        // `URLSession`'s delegate manage the response here (we need to be able to check
        // the progress or metrics so we can't use callback). This mean we need to send
        // a signal to mark the operation as finished in order to get it removed from the queue.
        // This is the reason of this method.
        state = .finished
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
