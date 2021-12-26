//
//  File.swift
//  
//
//  Created by Daniele Margutti on 26/12/21.
//

import Foundation

extension HTTPRequest {
    
    /// A set of common keys you can use to fill the `userInfo` keys of your request.
    public enum UserInfoKeys: Hashable {
        case fingerprint
        case subsystem
        case category
        case data
    }
    
}
