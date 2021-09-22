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

// MARK: - HTTPRawResponsePublisher

extension Combine.Publishers {
    
    public struct HTTPRawResponsePublisher: Publisher {
        public typealias Output = HTTPRawResponse
        public typealias Failure = Never
        
        // MARK: - Private Properties

        private let request: HTTPRequestProtocol
        private let client: HTTPClientProtocol

        // MARK: - Initialization
        
        public init(_ request: HTTPRequestProtocol, client: HTTPClientProtocol) {
            self.request = request
            self.client = client
        }
        
        // MARK: - Conformance to Publisher
        
        public func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, HTTPRawResponse == S.Input {
            let subscription = HTTPRawResponseSubscription(subscriber: subscriber,
                                                          client: client,
                                                          httpRequest: request)
            subscriber.receive(subscription: subscription)
        }
        
    }
    
}

// MARK: - HTTPRawResponseSubscription

private final class HTTPRawResponseSubscription<S: Subscriber>: Subscription where S.Input == HTTPRawResponse, S.Failure == Never {
    // MARK: - Private Properties
    
    var subscriber: S?
    var client: HTTPClientProtocol
    var httpRequest: HTTPRequestProtocol
    var observerToken: UInt64?
    
    // MARK: - Initialization
    
    init(subscriber: S, client: HTTPClientProtocol, httpRequest: HTTPRequestProtocol) {
        self.subscriber = subscriber
        self.client = client
        self.httpRequest = httpRequest
    }
    
    // MARK: - Conformance to Subscription
    
    func request(_ demand: Subscribers.Demand) {
        observerToken = httpRequest.responseObservers.add({ [weak self] rawResponse in
            _ = self?.subscriber?.receive(rawResponse)
            self?.subscriber?.receive(completion: .finished)
        })
        
        client.execute(request: httpRequest)
    }
    
    func cancel() {
        if let token = observerToken {
            httpRequest.responseObservers.remove(token)
        }
        subscriber = nil
    }
    
}

#endif
