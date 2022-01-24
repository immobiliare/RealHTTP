//
//  RealHTTP
//  Lightweight Async/Await Network Layer/Stubber for Swift
//
//  Created & Maintained by Mobile Platforms Team @ ImmobiliareLabs.it
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Authors:
//   - Daniele Margutti <hello@danielemargutti.com>
//
//  Copyright ©2022 Immobiliare.it SpA.
//  Licensed under MIT License.
//

import Foundation
import Combine
import Network

/// Network reachability changes can be monitored using the built-in
/// Combine publisher or an async stream.
public final class HTTPNetReachability: ObservableObject {
    
    // MARK: - Public Properties
    
    /// Shared main object.
    public static let shared = HTTPNetReachability()
    
    /// Connection informations.
    /// You can subscribe to it in order to receive updates.
    @Published
    public private(set) var currentPath: NWPath
    
    /// Combine publisher.
    public private(set) lazy var publisher = createPublisher()
    
    /// AsyncStream publisher.
    public private(set) lazy var stream = createAsyncStream()

    // MARK: - Private Properties
    
    /// Underlying monitor.
    private let monitor: NWPathMonitor
    
    /// Subject.
    private lazy var subject = CurrentValueSubject<NWPath, Never>(monitor.currentPath)
    
    /// Subscription bag.
    private var subscription: AnyCancellable?

    // MARK: - Initialization
    
    /// Initialize a new instance of the reachability object with a custom
    /// configuration.
    ///
    /// - Parameters:
    ///   - requiredInterface: required interfaces to monitor, by default is `nil`.
    ///   - prohibitedInterfaces: excluded interfaces, by default is `nil`.
    ///   - queue: dispatch queue, by default is `main`.
    public init(requiredInterface: NWInterface.InterfaceType? = nil,
                prohibitedInterfaces: [NWInterface.InterfaceType]? = nil,
                queue: DispatchQueue = .main) {
        
        precondition(!(requiredInterface != nil && prohibitedInterfaces != nil), "Configuration is not supported")

        if let requiredInterfaceType = requiredInterface {
            monitor = NWPathMonitor(requiredInterfaceType: requiredInterfaceType)
        } else if let prohibitedInterfaceTypes = prohibitedInterfaces {
            // Specified prohibited interfaces are reserved only to particular operating systems version
            if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) {
                monitor = NWPathMonitor(prohibitedInterfaceTypes: prohibitedInterfaceTypes)
            } else {
                preconditionFailure("prohibitedInterfaceTypes IS supported by this OS version")
            }
        } else {
            monitor = NWPathMonitor()
        }

        currentPath = monitor.currentPath

        monitor.pathUpdateHandler = { [weak self] path in
            self?.currentPath = path
            self?.subject.send(path)
        }

        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
        subject.send(completion: .finished)
    }
    
    // MARK: - Private Function
    
    private func createPublisher() -> AnyPublisher<NWPath, Never> {
        subject.eraseToAnyPublisher()
    }
    
    private func createAsyncStream() -> AsyncStream<NWPath> {
        AsyncStream { continuation in
            var subscription: AnyCancellable?
            
            subscription = subject.sink { _ in
                continuation.finish()
            } receiveValue: { value in
                continuation.yield(value)
            }
            
            self.subscription = subscription
        }
    }
}

// MARK: - NWPath

extension NWPath {
    
    /// Is network reachable.
    public var isReachable: Bool {
        status == .satisfied
    }

}
