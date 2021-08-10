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

public final class MockURLProtocol: URLProtocol {
    
    // MARK: - Private Properties
    
    private var responseWorkItem: DispatchWorkItem?

    // MARK: - Overrides
    
    public override func startLoading() {
        
    }
    
    public override func stopLoading() {
        responseWorkItem?.cancel()
    }
    
    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }
    
    
    
}
