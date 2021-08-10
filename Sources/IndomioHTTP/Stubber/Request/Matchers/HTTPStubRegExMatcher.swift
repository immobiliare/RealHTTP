//
//  File.swift
//  
//
//  Created by Daniele on 10/08/21.
//

import Foundation

public class HTTPStubRegExMatcher: HTTPStubMatcher {
    
    public func request(_ request: URLRequest, matchStub stub: HTTPStubRequest) -> Bool {
        false
    }
    
    
}
