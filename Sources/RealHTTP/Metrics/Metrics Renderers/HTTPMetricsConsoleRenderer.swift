//
//  IndomioHTTP
//
//  Created by the Mobile Team @ ImmobiliareLabs
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Copyright ©2021 Immobiliare.it SpA. All rights reserved.
//  Licensed under MIT License.
//


import Foundation

/// This is a concrete implementation of the `HTTPMetricsRenderer` protocol which allows to
/// print the metrics for an http request.
/// Original work by:
///  - Norsk rikskringkasting
///  - https://github.com/nrkno/Tumbleweed
///
/// This is the format you will see for each metric value:
///
/// ```
/// Task ID: 1 lifetime: 485.3ms redirects: 0
/// GET https://url.com/get -> 200 application/json, through local-cache
/// protocol: ??? proxy: false reusedconn: true
/// request           |                                                                                |   0.0ms
/// response          |################################################################################|   1.0ms
///                                                                                                total   1.0ms
/// GET https://url.com/get -> 200 application/json, through network-load
/// protocol: http/1.1 proxy: false reusedconn: false
/// domain lookup     |######                                                                          |  34.0ms
/// connect           |      #######################################################                   | 316.0ms
/// secure connection |                       ######################################                   | 216.0ms
/// request           |                                                             #                  |   0.1ms
/// response          |                                                                               #|   0.2ms
///                                                                                              total   465.5ms
/// ```
public struct HTTPMetricsConsoleRenderer: HTTPMetricsRenderer {
    public typealias Columns = (left: Int, middle: Int, right: Int)
    
    // MARK: - Private Properties
    
    /// Formatting options
    private let columns: Columns
    
    /// Printer functions
    public var printer: (String) -> Void = {
        print($0)
    }

    // MARK: - Initialization
    
    /// Initialize with given columns formatting options.
    ///
    /// - Parameter columns: options for columns, left, middle and right.
    public init(columns: Columns = (left: 18, middle: 82, right: 8)) {
        self.columns = columns
    }
    
    // MARK: - Public Functions

    public func render(with stats: HTTPRequestMetrics) {
        var buffer: [String] = []
        buffer.append("Task ID: \(stats.task.taskIdentifier) lifetime: \(stats.taskInterval.duration.ms) redirects: \(stats.redirectCount)")
        
        for metric in stats.metrics {
            buffer.append(renderHeader(with: metric))
            buffer.append(renderMeta(with: metric))
            let total = totalDateInterval(from: metric)
            for line in metric.stages.filter({ $0.kind != .total }) {
                buffer.append(renderDuration(line: line, total: total))
            }
            if let total = total {
                buffer.append(renderMetricSummary(for: total))
            }
        }

        printer(buffer.joined(separator: "\n"))
    }
    
    // MARK: - Private Functions

   private func totalDateInterval(from metric: HTTPMetric) -> DateInterval? {
        if let total = metric.stages.filter({ $0.kind == .total }).first {
            return total.interval
        } else if let first = metric.stages.first  {
            // calculate total from all available Durations
            var total = first.interval
            total.duration += metric.stages.dropFirst().reduce(TimeInterval(0), { accumulated, duration in
                return accumulated + duration.interval.duration
            })
            return total
        }
        return nil
    }

    private func renderHeader(with metric: HTTPMetric) -> String {
        let method = metric.transactionMetrics.request.httpMethod ?? "???"
        let url = metric.transactionMetrics.request.url?.absoluteString ?? "???"

        let responseLine: String
        if let response = metric.transactionMetrics.response as? HTTPURLResponse {
            let mime = response.mimeType ?? ""
            responseLine = "\(response.statusCode) \(mime)"
        } else {
            responseLine = "[response error]"
        }
        return "\(method) \(url) -> \(responseLine), through \(metric.transactionMetrics.resourceFetchType.name)"
    }

    private func renderDuration(line: HTTPMetric.Stage, total: DateInterval?) -> String {
        let name = line.kind.name.padding(toLength: columns.left, withPad: " ", startingAt: 0)
        let plot = total.flatMap({ visualize(interval: line.interval, total: $0, within: self.columns.middle) }) ?? ""
        let time = line.interval.duration.ms.leftPadding(toLength: columns.right, withPad: " ")
        return "\(name)\(plot)\(time)"
    }

    private func visualize(interval: DateInterval, total: DateInterval, within: Int = 100) -> String {
        precondition(total.intersects(total), "supplied duration does not intersect with the total duration")
        let width = within - 2
        if interval.duration == 0 {
            return "|" + String(repeatElement(" ", count: width)) + "|"
        }

        let relativeStart = (interval.start.timeIntervalSince1970 - total.start.timeIntervalSince1970) / total.duration
        let relativeEnd = 1.0 - (total.end.timeIntervalSince1970 - interval.end.timeIntervalSince1970) / total.duration

        let factor = 1.0 / Double(width)
        let startIndex = Int((relativeStart / factor))
        let endIndex = Int((relativeEnd / factor))

        let line: [String] = (0..<width).map { position in
            if position >= startIndex && position <= endIndex {
                return "#"
            } else {
                return " "
            }
        }
        return "|\(line.joined())|"
    }

    private func renderMeta(with metric: HTTPMetric) -> String {
        let networkProtocolName = metric.transactionMetrics.networkProtocolName ?? "???"
        let meta = [
            "protocol: \(networkProtocolName)",
            "proxy: \(metric.transactionMetrics.isProxyConnection)",
            "reusedconn: \(metric.transactionMetrics.isReusedConnection)",
        ]
        return meta.joined(separator: " ")
    }

    private func renderMetricSummary(for interval: DateInterval) -> String {
        let width = columns.left + columns.middle + columns.right
        return "total   \(interval.duration.ms)".leftPadding(toLength: width, withPad: " ")
    }
    
}

// MARK: - TimeInterval Extension

private extension TimeInterval {
    
    /// Milliseconds formatting
    var ms: String {
        String(format: "%.1fms", self * 1000)
    }
    
}

// MARK: - String Extension

private extension String {
    
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let newLength = self.count
        guard newLength < toLength else {
            let i = index(startIndex, offsetBy: newLength - toLength)
            return String(self[i..<endIndex])
        }

        return String(repeatElement(character, count: toLength - newLength)) + self
    }
    
}
