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

// MARK: - HTTPMetrics

/// It includes all the metrics related to a request+response executed.
public struct HTTPMetrics {
    
    /// Each metrics  contains the taskInterval and redirectCount, as well as metrics for each
    /// request-and-response transaction made during the execution of the task.
    public let requests: [RequestMetrics]
    
    /// First request stafes
    internal var stages: [HTTPMetrics.RequestMetrics.Stage] {
        requests.first?.stages ?? []
    }
    
    /// Elapsed time interval since the start of the first request down the last response.
    /// Zero is returned if cannot be estimated.
    public var elapsedInterval: TimeInterval {
        guard let start = requests.first?[.request]?.interval.start,
              let end = requests.first?[.response]?.interval.end else {
                  return 0
              }

        return end.timeIntervalSince(start)
    }
    
    /// Task metrics.
    public let taskMetrics: URLSessionTaskMetrics?
    
    /// Associated task.
    public private(set) weak var task: URLSessionTask?
    
    /// Number of redirects made.
    public var countRedirects: Int {
        return taskMetrics?.redirectCount ?? 0
    }
    
    // MARK: - Initialization
    
    /// Initialize the object with the metrics gathered for a task.
    internal init?(metrics: URLSessionTaskMetrics?, task: URLSessionTask?) {
        self.taskMetrics = metrics
        self.task = task
        
        let list = metrics?.transactionMetrics.compactMap({
            RequestMetrics(metrics: $0)
        }) ?? []
        
        guard !list.isEmpty else {
            return nil
        }
        
        self.requests = list
    }
    
    // MARK: - Public Functions
    
    /// Render with custom renderer.
    ///
    /// - Parameter renderer: renderer, if not set the default HTTPMetricsConsoleRenderer is used.
    public func render(with renderer: HTTPMetricsRenderer = HTTPMetricsConsoleRenderer()) {
        renderer.render(with: self)
    }
    
    
}

// MARK: - RequestMetrics

public extension HTTPMetrics {
    
    /// `RequestMetrics` represent a single request/response for an executed
    /// task and contains all gathered stats about it.
    struct RequestMetrics {
        
        // MARK: - Public Properties
        
        /// Stages of a connection.
        public let stages: [Stage]
        
        /// Underlying transaction metrics.
        public let transactionMetrics: URLSessionTaskTransactionMetrics
        
        /// The transaction request.
        public var request: URLRequest {
            transactionMetrics.request
        }
        
        // MARK: - Initialization
        
        /// Initialize a new instance of metrics from the collected metrics of `URLSession`
        ///
        /// - Parameter metrics: metrics instance
        internal init?(metrics: URLSessionTaskTransactionMetrics?) {
            guard let metrics = metrics else {
                return nil
            }
            
            self.transactionMetrics = metrics
            self.stages = [
                Stage.stage(.domainLookup, metrics.domainLookupStartDate, metrics.domainLookupEndDate),
                Stage.stage(.connect, metrics.connectStartDate, metrics.connectEndDate),
                Stage.stage(.secureConnect, metrics.secureConnectionStartDate, metrics.secureConnectionEndDate),
                Stage.stage(.request, metrics.requestStartDate, metrics.requestEndDate),
                Stage.stage(.response, metrics.responseStartDate, metrics.responseEndDate),
                Stage.stage(.fetchStart, metrics.domainLookupStartDate, metrics.responseEndDate),
                Stage.stage(.total, metrics.domainLookupStartDate, metrics.responseEndDate)
            ].compactMap { $0 }
            
        }
        
        // MARK: - Public Functions
        
        /// Get specific stage from metrics.
        public subscript(stage: Stage.Kind) -> Stage? {
            stages.first(where: {
                $0.kind == stage
            })
        }
        
    }
    
}

public extension HTTPMetrics.RequestMetrics {
    
    /// Each request is composed by a list of individual operations.
    /// This object represent a single operation gathered
    /// from the underlying `URLSessionTaskTransactionMetrics` object.
    ///
    /// See the graph here for more infos:
    /// <https://developer.apple.com/documentation/foundation/urlsessiontasktransactionmetrics#>
    struct Stage: Comparable {
        /// Kind of operation.
        public let kind: Kind
        
        /// Time interval of the operation. It includes the start date and
        /// depending by the kind of the operation an end date.
        ///
        /// For all metrics with a start and end date, if an aspect of the task was not completed,
        /// then its corresponding end date metric is nil.
        /// This can happen if name lookup begins, but the operation either times out, fails,
        /// or the client cancels the task before the name can be resolved.
        public let interval: DateInterval
        
        /// Total time elapsed since the start and end of the request.
        /// It return `nil` if interval cannot be evaluated because request did finished early
        /// due to an error occurred in that phase.
        public var totalInterval: TimeInterval {
            return interval.end.timeIntervalSince(interval.end)
        }
        
        // MARK: - Initialization
        
        fileprivate static func stage(_ kind: Stage.Kind, _ start: Date?, _ end: Date?) -> Stage? {
            guard let start = start, let end = end else {
                return nil
            }
            
            return Stage(kind: kind, interval: .init(start: start, end: end))
        }
        
        public static func < (lhs: HTTPMetrics.RequestMetrics.Stage,
                              rhs: HTTPMetrics.RequestMetrics.Stage) -> Bool {
            lhs.kind < rhs.kind
        }
        
        public static func == (lhs: HTTPMetrics.RequestMetrics.Stage,
                               rhs: HTTPMetrics.RequestMetrics.Stage) -> Bool {
            lhs.kind == rhs.kind
        }
        
    }
    
}

public extension HTTPMetrics.RequestMetrics.Stage {
    
    /// Identify the stage of a request.
    /// - `fetchStart`: connection to the network is about to be opened.
    /// - `domainLookup`: domain lookup stage.
    /// - `connect`: fetch the document using an HTTP request.
    /// - `secureConnect`: secure connection handshake starts.
    /// - `request`: request start.
    /// - `response`: response received.
    /// - `total`: total interval.
    enum Kind: Int, Comparable {
        case fetchStart
        case domainLookup
        case connect
        case secureConnect
        case request
        case response
        case total
        
        public var name: String {
            switch self {
            case .fetchStart:       return "fetch start"
            case .domainLookup:     return "domain lookup"
            case .connect:          return "connect"
            case .secureConnect:    return "secure connection"
            case .request:          return "request"
            case .response:         return "response"
            case .total:            return "total"
            }
        }

        public static func < (lhs: HTTPMetrics.RequestMetrics.Stage.Kind,
                              rhs: HTTPMetrics.RequestMetrics.Stage.Kind) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
    
}
