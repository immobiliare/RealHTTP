//
//  File.swift
//  
//
//  Created by Daniele Margutti on 26/12/21.
//

import Foundation

public protocol HTTPRequestProtocol: AnyObject {

    func execute(_ client: HTTPClient?) async -> HTTPResponseProtocol
    
}
