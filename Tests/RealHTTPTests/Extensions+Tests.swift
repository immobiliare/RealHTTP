//
//  Extensions+Tests.swift
//  
//
//  Created by Kondamon on 01.06.22.
//

import XCTest
import XCTest
@testable import RealHTTP

class Extensions_Tests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCreateTemporaryFolderIfNeeded() throws {
        let fm = FileManager.default
        let temporaryFilePath = fm.temporaryFileLocation().path as NSString
        let temporaryFolderPath = temporaryFilePath.deletingLastPathComponent
     
        // Delete existing temporary folder
        do {
            try fm.removeItem(atPath: temporaryFolderPath)
        } catch {
            
        }
        
        precondition(fm.fileExists(atPath: temporaryFolderPath) == false,
                     "The temporary folder was not successfully deleted")
        
        // creates new temporary folder
        _ = fm.temporaryFileLocation()
        XCTAssertTrue(fm.fileExists(atPath: temporaryFolderPath))
    }

    

}
