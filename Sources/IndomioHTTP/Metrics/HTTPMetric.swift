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

/// Represent a single transaction metrics entry.
public struct HTTPMetric {
    
    // MARK: - Public Properties
    
    /// Metrics.
    public let transactionMetrics: HTTPMeasurableProtocol
    
    /// Stages which compose the request, each one is an operation executed.
    public let stages: [Stage]

    // MARK: - Initialization
    
    /// Initialize a new metric entry with given data from `URLSessionMetrics` data.
    ///
    /// - Parameter metrics: metrics.
    internal init(transactionMetrics metrics: HTTPMeasurableProtocol) {
        func stage(_ kind: Stage.Kind, _ start: Date?, _ end: Date?) -> Stage? {
            guard let start = start, let end = end else {
                return nil
            }
            
            return Stage(kind, startDate: start, endDate: end)
        }
        
        self.transactionMetrics = metrics

        // Evaluate the stages of this request
        var stages: [Stage] = [
            stage(.domainLookup, metrics.domainLookupStartDate, metrics.domainLookupEndDate),
            stage(.connect, metrics.connectStartDate, metrics.connectEndDate),
            stage(.secureConnection, metrics.secureConnectionStartDate, metrics.secureConnectionEndDate),
            stage(.request, metrics.requestStartDate, metrics.requestEndDate),
            stage(.response, metrics.responseStartDate, metrics.responseEndDate),
            stage(.total, metrics.domainLookupStartDate, metrics.responseEndDate)
        ].compactMap { $0 }

        // Calculate the total time of the request
        if let request = stages.findStage(.request),
           let response = stages.findStage(.response),
           let index = stages.firstIndex(of: response),
           request.interval.duration > 0 {
            
            let duration = Stage(.server, startDate: response.interval.start, endDate: request.interval.end)
            stages.insert(duration, at: index)
        }

        self.stages = stages
    }
    
}

// MARK: - HTTPMetric.Stage

public extension HTTPMetric {
    
    /// A single stage of the metrics.
    struct Stage: Equatable {
        
        /// Type of stage.
        public let kind: Kind
        
        /// Duration of the stage
        public let interval: DateInterval
        
        /// Start date of the stage.
        public let startDate: Date
        
        /// End date of the stage.
        public let endDate: Date
        
        internal init(_ kind: Kind, startDate: Date, endDate: Date) {
            self.kind = kind
            self.startDate = startDate
            self.endDate = endDate
            self.interval = DateInterval(start: endDate, end: startDate)
        }
        
        public static func == (lhs: HTTPMetric.Stage, rhs: HTTPMetric.Stage) -> Bool {
            return rhs.kind == lhs.kind && rhs.interval == rhs.interval
        }
    }
    
}

// MARK: - HTTPMetric.Stage.Kind

public extension HTTPMetric.Stage {
    
    /// Stage classification.
    enum Kind {
        case domainLookup
        case connect
        case secureConnection
        case request
        case server
        case response
        case total
        
        public var name: String {
            switch self {
            case .domainLookup:     return "domain lookup"
            case .connect:          return "connect"
            case .secureConnection: return "secure connection"
            case .request:          return "request"
            case .server:           return "server"
            case .response:         return "response"
            case .total:            return "total"
            }
        }
        
    }
    
}

// MARK: - Other

private extension Array where Element == HTTPMetric.Stage {
    
    func findStage(_ stage: HTTPMetric.Stage.Kind) -> Element? {
        return self.filter({ $0.kind == stage }).first
    }
    
}

private extension Array {
    
    /// Append given object if it's not `nil`.
    /// - Parameters:
    ///   - obj: object to append if not nil.
    @discardableResult
    mutating func append(_ obj: Element?) -> Bool {
        guard let obj = obj else {
            return false
        }
        
        append(obj)
        return true
    }
    
}
