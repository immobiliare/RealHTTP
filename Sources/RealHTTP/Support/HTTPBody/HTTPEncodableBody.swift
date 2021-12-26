//
//  File.swift
//  
//
//  Created by Daniele Margutti on 26/12/21.
//

import Foundation

public protocol HTTPEncodableBody {
    
    func encodedData() throws -> Data
            
}

extension Data: HTTPEncodableBody {
    
    public func encodedData() throws -> Data {
        self
    }
    
}

extension String: HTTPEncodableBody {
    
    public func encodedData() throws -> Data {
        self.data(using: .utf8) ?? Data()
    }
    
}
