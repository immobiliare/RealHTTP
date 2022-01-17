//
//  RealHTTP
//
//  Created by the Mobile Team @ ImmobiliareLabs
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Copyright ©2021 Immobiliare.it SpA. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

internal class DataLoaderResponse {
    public typealias Completion = ((HTTPResponse) -> Void)

    var data: Data?
    var dataFileURL: URL?
    var metrics: URLSessionTaskMetrics?
    var error: Error?
    var urlResponse: URLResponse?
    var completion: Completion
    var request: HTTPRequest
    
    init(request: HTTPRequest, completion: @escaping Completion) {
        self.request = request
        self.completion = completion
    }

    func appendData(_ newData: Data) {
        if data == nil {
            data = newData
        } else {
            data?.append(newData)
        }
    }
}
