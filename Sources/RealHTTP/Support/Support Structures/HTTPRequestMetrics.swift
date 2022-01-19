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


/// `HTTPMetrics` is a wrapper class under `URLSessionTaskMetrics`. It just allow
/// to easily read the connection metrics.
public struct HTTPRequestMetrics {
    
    // MARK: - Public Properties
    
    /// Stages of a connection.
    public let stages: [Stage]
    
    /// Underlying transaction metrics.
    public let metrics: URLSessionTaskTransactionMetrics
    
    /// The transaction request.
    public var request: URLRequest {
        metrics.request
    }
    
    // MARK: - Initialization
    
    /// Initialize a new instance of metrics from the collected metrics of `URLSession`
    ///
    /// - Parameter metrics: metrics instance
    internal init?(metrics: URLSessionTaskTransactionMetrics?) {
        guard let metrics = metrics else {
            return nil
        }
        
        self.metrics = metrics
        self.stages = [
            Stage.stage(.domainLookup, metrics.domainLookupStartDate, metrics.domainLookupEndDate),
            Stage.stage(.connect, metrics.connectStartDate, metrics.connectEndDate),
            Stage.stage(.secureConnect, metrics.secureConnectionStartDate, metrics.secureConnectionEndDate),
            Stage.stage(.request, metrics.requestStartDate, metrics.requestEndDate),
            Stage.stage(.response, metrics.responseStartDate, metrics.responseEndDate),
            Stage.stage(.total, metrics.domainLookupStartDate, metrics.responseEndDate)
        ].compactMap { $0 }
        
    }
    
    /// Get specific stage from metrics.
    public subscript(stage: Stage.Kind) -> Stage? {
        stages.first(where: {
            $0.kind == stage
        })
    }
    
}

public extension HTTPRequestMetrics {
    
    /// Each request is composed by a list of individual operations.
    /// This object represent a single operation gathered
    /// from the underlying `URLSessionTaskTransactionMetrics` object.
    ///
    /// See the graph here for more infos:
    /// <https://developer.apple.com/documentation/foundation/urlsessiontasktransactionmetrics#>
    struct Stage: Comparable {
        public typealias Interval = (start: Date?, end: Date?)
        
        /// Kind of operation.
        public let kind: Kind
        
        /// Time interval of the operation. It includes the start date and
        /// depending by the kind of the operation an end date.
        ///
        /// For all metrics with a start and end date, if an aspect of the task was not completed,
        /// then its corresponding end date metric is nil.
        /// This can happen if name lookup begins, but the operation either times out, fails,
        /// or the client cancels the task before the name can be resolved.
        public let interval: Interval
        
        /// Total time elapsed since the start and end of the request.
        /// It return `nil` if interval cannot be evaluated because request did finished early
        /// due to an error occurred in that phase.
        public var totalInterval: TimeInterval? {
            guard let start = interval.start,
                  let end = interval.end else {
                return nil
            }
            
            return end.timeIntervalSince(start)
        }
        
        // MARK: - Initialization
        
        fileprivate static func stage(_ kind: Stage.Kind, _ start: Date?, _ end: Date?) -> Stage? {
            guard let start = start else {
                return nil
            }
            
            return Stage(kind: kind, interval: (start, end))
        }
        
        public static func < (lhs: HTTPRequestMetrics.Stage, rhs: HTTPRequestMetrics.Stage) -> Bool {
            lhs.kind < rhs.kind
        }
        
        public static func == (lhs: HTTPRequestMetrics.Stage, rhs: HTTPRequestMetrics.Stage) -> Bool {
            lhs.kind == rhs.kind
        }
        
    }
    
}

public extension HTTPRequestMetrics.Stage {
    
    /// Identify the stage of a request.
    /// -
    enum Kind: Int, Comparable {
        case total
        case domainLookup
        case connect
        case secureConnect
        case request
        case response
        
        public static func < (lhs: HTTPRequestMetrics.Stage.Kind, rhs: HTTPRequestMetrics.Stage.Kind) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
    
}
