//
//  File.swift
//  
//
//  Created by Daniele on 10/08/21.
//

import Foundation

public enum HTTPStubberErrors: Error {
    case matchStubNotFound(URLRequest)
}
