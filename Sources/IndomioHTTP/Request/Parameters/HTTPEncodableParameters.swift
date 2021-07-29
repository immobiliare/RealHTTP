//
//  File.swift
//  
//
//  Created by Daniele on 29/07/21.
//

import Foundation

public protocol HTTPEncodableParameters {
 
    func encode() throws -> Data
    
}
