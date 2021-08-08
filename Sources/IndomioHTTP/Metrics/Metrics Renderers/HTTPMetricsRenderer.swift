//
//  IndomioNetwork
//
//  Created by the Mobile Team @ ImmobiliareLabs
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Copyright ©2021 Immobiliare.it SpA. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

/// An object which is conform to this protocol allows you to render
/// the statistics about the http operation executed.

public protocol HTTPMetricsRenderer {
    
    /// Implement a render function which allows you to print the data.
    ///
    /// - Parameter stats: stats to print.
    func render(with stats: HTTPRequestMetrics)
    
}
