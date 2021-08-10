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

public extension HTTPRequest {
    
    /// Add a new observer to get info about the raw response.
    ///
    /// - Parameter callback: callback.
    /// - Parameter queue: queue in which the event should be dispatched.
    /// - Returns: Self
    @discardableResult
    func setResult(_ queue: DispatchQueue = .main, _ callback: @escaping ResultCallback) -> Self {
        _ = objectObservers.add((queue, callback))
        dispatchEvents()
        return self
    }
    
    /// Add a new observer to get info about the result response.
    ///
    /// - Parameter callback: callback.
    ///   - queue: queue in which the event should be dispatched.
    /// - Returns: Self
    @discardableResult
    func setResponse(_ queue: DispatchQueue = .main, _ callback: @escaping DataResultCallback) -> Self {
        _ = responseObservers.add((queue, callback))
        dispatchEvents()
        return self
    }
    
    /// Add a new observer to omonitor the request's progression.
    ///
    /// - Parameters:
    ///   - queue: queue in which the event should be dispatched.
    ///   - callback: callback to call.
    /// - Returns: Self
    @discardableResult
    func setProgress(_ queue: DispatchQueue = .main, _ callback: @escaping ProgressCallback) -> Self {
        _ = progressObservers.add((queue, callback))
        return self
    }
    
}
