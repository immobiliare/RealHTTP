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

extension URL {
    
    // MARK: - Public Functions

    /// Returns the base URL string build with the scheme, host and path.
    /// For example:
    /// "https://www.apple.com/v1/test?param=test"
    /// would be "https://www.apple.com/v1/test"
    public var baseString: String? {
        guard let scheme = scheme, let host = host else { return nil }
        return scheme + "://" + host + path
    }

    // MARK: - Internal Functions
    
    /// Copy the temporary file for location in a non deletable path.
    ///
    /// - Parameters:
    ///   - task: task.
    ///   - request: request.
    /// - Returns: URL?
    internal func copyFileToDefaultLocation(task: URLSessionDownloadTask,
                                            forRequest request: HTTPRequest) -> URL? {
        let fManager = FileManager.default
        
        let fileName = UUID().uuidString
        let documentsDir = NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true).first! as NSString
        let destinationURL = URL(fileURLWithPath: documentsDir.appendingPathComponent(fileName))
        
        do {
            try fManager.copyItem(at: self, to: destinationURL)
            return destinationURL
        } catch {
            return nil
        }
    }
    
}
