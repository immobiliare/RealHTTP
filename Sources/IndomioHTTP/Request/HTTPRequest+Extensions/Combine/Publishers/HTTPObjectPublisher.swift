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
#if canImport(Combine)
import Combine

// MARK: - HTTPObjectPublisher

extension Combine.Publishers {
    
    public struct HTTPObjectPublisher<Object: HTTPDecodableResponse>: Publisher {
        public typealias Output = Result<Object, Error>
        public typealias Failure = Never
        
        // MARK: - Private Properties

        private let request: HTTPRequest<Object>
        private let client: HTTPClientProtocol
        private let queue: DispatchQueue

        // MARK: - Initialization
        
        public init(_ request: HTTPRequest<Object>, client: HTTPClientProtocol, queue: DispatchQueue) {
            self.request = request
            self.client = client
            self.queue = queue
        }
        
        // MARK: - Conformance to Publisher
        
        public func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Result<Object, Error> == S.Input {
            let subscription = HTTPObjectSubscription(subscriber: subscriber,
                                                          client: client,
                                                          httpRequest: request,
                                                          queue: queue)
            subscriber.receive(subscription: subscription)
        }
        
    }
    
}

// MARK: - HTTPObjectPublisher

private final class HTTPObjectSubscription<S: Subscriber, Object: HTTPDecodableResponse>: Subscription where S.Input == Result<Object, Error>, S.Failure == Never {
    
    // MARK: - Private Properties

    var subscriber: S?
    var client: HTTPClientProtocol
    var httpRequest: HTTPRequest<Object>
    var queue: DispatchQueue
    
    // MARK: - Initialization
    
    init(subscriber: S, client: HTTPClientProtocol, httpRequest: HTTPRequest<Object>, queue: DispatchQueue ) {
        self.subscriber = subscriber
        self.client = client
        self.httpRequest = httpRequest
        self.queue = queue
    }
    
    // MARK: - Conformance to Subscription
    
    func request(_ demand: Subscribers.Demand) {
        httpRequest.run(in: client).response(in: queue) { [weak self] result in
            _ = self?.subscriber?.receive(result)
            self?.subscriber?.receive(completion: .finished)
        }
    }
    
    func cancel() {
        subscriber = nil
    }
    
}

#endif


