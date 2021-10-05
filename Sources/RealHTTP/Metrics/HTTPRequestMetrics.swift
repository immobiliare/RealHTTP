//
//  File.swift
//  
//
//  Created by Daniele on 08/08/21.
//

import Foundation

/// This object encapsulate all the metrics information about a given request.
/// This data is collected by the `URLSession` - and therefore by the `HTTPClient` instance - which execute the
/// request.
public struct HTTPRequestMetrics {
    
    // MARK: - Public Properties
    
    /// Associated task.
    public let task: URLSessionTask
    
    /// Collected metrics.
    public let metrics: [HTTPMetric]
    
    /// Number of redirect.
    public let redirectCount: Int
    
    /// Total time spent on task.
    public let taskInterval: DateInterval
    
    // MARK: - Initialization
    
    /// Initialize a new metrics collection from the response of the `URLSession`.
    ///
    /// - Parameters:
    ///   - sessionTaskMetrics: metrics acquired for task by the url session.
    ///   - task: task associated.
    internal init(source sessionTaskMetrics: URLSessionTaskMetrics, task: URLSessionTask) {
        self.task = task
        self.redirectCount = sessionTaskMetrics.redirectCount
        self.taskInterval = sessionTaskMetrics.taskInterval
        self.metrics = sessionTaskMetrics.transactionMetrics.map {
            HTTPMetric(transactionMetrics: $0)
        }
    }
    
    // MARK: - Public Functions
    
    /// Render with custom renderer.
    ///
    /// - Parameter renderer: renderer, if not set the default HTTPMetricsConsoleRenderer is used.
    public func render(with renderer: HTTPMetricsRenderer = HTTPMetricsConsoleRenderer()) {
        renderer.render(with: self)
    }
    
}
