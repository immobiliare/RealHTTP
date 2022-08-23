//
//  RealHTTP
//  Lightweight Async/Await Network Layer/Stubber for Swift
//
//  Created & Maintained by Mobile Platforms Team @ ImmobiliareLabs.it
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Authors:
//   - Daniele Margutti <hello@danielemargutti.com>
//
//  Copyright ©2022 Immobiliare.it SpA.
//  Licensed under MIT License.
//

import Foundation

/// An object which is conform to this protocol allows you to render
/// the statistics about the http operation executed.

public protocol HTTPMetricsRenderer {
    
    /// Implement a render function which allows you to print the data.
    ///
    /// - Parameter stats: stats to print.
    func render(with stats: HTTPMetrics)
    
}
