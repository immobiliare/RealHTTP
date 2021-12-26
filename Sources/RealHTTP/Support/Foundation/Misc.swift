//
//  File.swift
//  
//
//  Created by Daniele Margutti on 26/12/21.
//

import Foundation

extension Array where Element == String {
    
    internal func joinedWithAmpersands() -> String {
        joined(separator: "&")
    }
    
}
