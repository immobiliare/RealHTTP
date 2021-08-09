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

public extension HTTPRequest {
    
    /// link with the raw response.
    ///
    /// - Parameter callback: callback.
    /// - Returns: Self
    @discardableResult
    func response(in queue: DispatchQueue? = .main, _ callback: @escaping ResultCallback) -> Self {
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
    func rawResponse(in queue: DispatchQueue? = .main, _ callback: @escaping DataResultCallback) -> Self {
        stateQueue.sync {
            rawResultCallback = (queue, callback)
            dispatchEvents()
        }
        return self
    }
    
    @discardableResult
    func progress(in queue: DispatchQueue? = .main, _ callback: @escaping ProgressCallback) -> Self {
        stateQueue.sync {
            progressCallback = (queue, callback)
        }
        return self
    }
    
}
