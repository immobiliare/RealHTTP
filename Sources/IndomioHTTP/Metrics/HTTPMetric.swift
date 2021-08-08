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
        self.transactionMetrics = metrics

        func getStage(_ kind: Stage.Kind, _ start: Date?, _ end: Date?) -> Stage? {
            guard let start = start, let end = end else {
                return nil
            }
            
            return Stage(type: kind, interval: DateInterval(start: start, end: end))
        }

        // Evaluate the stages of this request
        var stages = [Stage]()
        stages.append( getStage(.domainLookup, metrics.domainLookupStartDate, metrics.domainLookupEndDate))
        stages.append( getStage(.connect, metrics.connectStartDate, metrics.connectEndDate))
        stages.append( getStage(.secureConnection, metrics.secureConnectionStartDate, metrics.secureConnectionEndDate))
        stages.append( getStage(.request, metrics.requestStartDate, metrics.requestEndDate))
        stages.append( getStage(.response, metrics.responseStartDate, metrics.responseEndDate))
        stages.append( getStage(.total, metrics.domainLookupStartDate, metrics.responseEndDate))

        // Calculate the total time of the request
        if let request = stages.findStage(.request),
           let response = stages.findStage(.response),
           let index = stages.firstIndex(of: response),
           request.interval.duration > 0 {
            
            let interval = DateInterval(start: request.interval.end, end: response.interval.start)
            let duration = Stage(type: .server, interval: interval)
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
        public let type: Kind
        
        /// Duration of the stage
        public let interval: DateInterval
        
        public static func ==(lhs: HTTPMetric.Stage, rhs: HTTPMetric.Stage) -> Bool {
            return rhs.type == lhs.type && rhs.interval == rhs.interval
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
        return self.filter({ $0.type == stage }).first
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
