//
//  RealHTTP
//  Lightweight Async/Await Network Layer/Stubber for Swift
//
//  Created & Maintained by Mobile Platforms Team @ ImmobiliareLabs.it
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Created by: Daniele Margutti <hello@danielemargutti.com>

//  CONTRIBUTORS:
//  Thank you to all the contributors who made this project better:
//  <https://github.com/immobiliare/RealHTTP/graphs/contributors>
//
//  Copyright ©2022 Immobiliare.it SpA.
//  Licensed under MIT License.
//

import Foundation

public protocol HTTPFormattible {
    
    /// Produce a formatted version sendable along HTTP request.
    ///
    /// - Returns: String
    func httpFormatted() -> String
    
}

extension String: HTTPFormattible {
    
    public func httpFormatted() -> String {
        self
    }
    
}

extension Locale: HTTPFormattible {
    
    public func httpFormatted() -> String {
        identifier
    }
    
}

extension Int: HTTPFormattible {
    
    public func httpFormatted() -> String {
        String(self)
    }
    
}

extension Date: HTTPFormattible {
    
    public func httpFormatted() -> String {
        DateFormatter.http.string(from: self)
    }
    
}

extension DateFormatter {
    
    private func configured(with block: (inout DateFormatter) -> Void) -> DateFormatter {
        var copy = self
        block(&copy)
        return copy
    }

    static let http = DateFormatter().configured {
        $0.calendar = Calendar(identifier: .gregorian)
        $0.timeZone = TimeZone(secondsFromGMT: 0)
        $0.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
    }
    
}
