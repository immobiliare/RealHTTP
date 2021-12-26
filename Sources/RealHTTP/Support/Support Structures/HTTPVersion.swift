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

/// Defines the HTTP protocol version used for request.
public struct HTTPVersion: Equatable, Hashable, Codable, RawRepresentable,
                           ExpressibleByFloatLiteral {
    
    // MARK: - Available Values
    
    public static let v0_9: Self = 0.9
    public static let v1_0: Self = 1.0
    public static let v1_1: Self = 1.1
    public static let v2_0: Self = 2.0
    public static let v3_0: Self = 3.0
    public static let `default`: Self = v2_0
    
    // MARK: - Public Properties
    
    public let rawValue: String

    // MARK: - Initialization
    
    /// Initialize with string value.
    ///
    /// - Parameter rawValue: value to initialize.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    /// Initialize with numeric version value.
    ///
    /// - Parameter version: version.
    public init(version: Double) {
        rawValue = NumberFormatter.httpVersion.string(from: NSNumber(value: version)) ?? String(version)
    }
    
    /// Initialize with float value as version.
    ///
    /// - Parameter value: version.
    public init(floatLiteral value: Double) {
        self.init(version: value)
    }
    
    // MARK: - Public Properties
    
    /// Evaluate the format for request.
    public var standardFormat: String {
        "HTTP/\(rawValue)"
    }
    
}

// MARK: NumberFormatter Extension

private extension NumberFormatter {
    
    private func configured(with block: (inout NumberFormatter) -> Void) -> NumberFormatter {
        var copy = self
        block(&copy)
        return copy
    }

    static let httpVersion = NumberFormatter().configured {
        $0.allowsFloats = false
        $0.alwaysShowsDecimalSeparator = true
        $0.minimumFractionDigits = 1
        $0.maximumFractionDigits = 1
        $0.minimumIntegerDigits = 1
        $0.maximumIntegerDigits = 1
    }
    
}
