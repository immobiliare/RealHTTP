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
#if canImport(Combine)
import Combine

// MARK: - HTTPResultPublisher

extension Combine.Publishers {
    
    public struct HTTPResultPublisher<Object: HTTPDecodableResponse>: Publisher {
        public typealias Output = Result<Object, HTTPError>
        public typealias Failure = Never
        
        // MARK: - Private Properties

        private let request: HTTPRequest<Object>
        private let client: HTTPClientProtocol

        // MARK: - Initialization
        
        public init(_ request: HTTPRequest<Object>, client: HTTPClientProtocol) {
            self.request = request
            self.client = client
        }
        
        // MARK: - Conformance to Publisher
        
        public func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Result<Object, HTTPError> == S.Input {
            let subscription = HTTPResultSubscription(subscriber: subscriber,
                                                          client: client,
                                                          httpRequest: request)
            subscriber.receive(subscription: subscription)
        }
        
    }
    
}

// MARK: - HTTPResultSubscription

private final class HTTPResultSubscription<S: Subscriber, Object: HTTPDecodableResponse>: Subscription where S.Input == Result<Object, HTTPError>, S.Failure == Never {
    
    // MARK: - Private Properties

    var subscriber: S?
    var client: HTTPClientProtocol
    var httpRequest: HTTPRequest<Object>
    
    // MARK: - Initialization
    
    init(subscriber: S, client: HTTPClientProtocol, httpRequest: HTTPRequest<Object>) {
        self.subscriber = subscriber
        self.client = client
        self.httpRequest = httpRequest
    }
    
    // MARK: - Conformance to Subscription
    
    func request(_ demand: Subscribers.Demand) {
        httpRequest.onResult { [weak self] result in
            _ = self?.subscriber?.receive(result)
            self?.subscriber?.receive(completion: .finished)
        }
        
        _ = httpRequest.run(in: client)
    }
    
    func cancel() {
        subscriber = nil
    }
    
}

#endif


