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

// MARK: - HTTPMeasurableProtocol

/// This is just a protocol which describe a measurable resources.
/// `URLSessionTaskTransactionMetrics` is conform to this protocol.
public protocol HTTPMeasurableProtocol {
    var request: URLRequest { get }
    var response: URLResponse? { get }

    var networkProtocolName: String? { get }
    var isProxyConnection: Bool { get }
    var isReusedConnection: Bool { get }
    var resourceFetchType: URLSessionTaskMetrics.ResourceFetchType { get }

    var domainLookupStartDate: Date? { get }
    var domainLookupEndDate: Date? { get }

    var connectStartDate: Date? { get }
    var connectEndDate: Date? { get }
    var secureConnectionStartDate: Date? { get }
    var secureConnectionEndDate: Date? { get }

    var requestStartDate: Date? { get }
    var requestEndDate: Date? { get }
    var responseStartDate: Date? { get }
    var responseEndDate: Date? { get }
}

extension URLSessionTaskTransactionMetrics: HTTPMeasurableProtocol {
    
}

// MARK: - URLSessionTaskMetrics.ResourceFetchType Extension

extension URLSessionTaskMetrics.ResourceFetchType {
    
    var name: String {
        switch self {
        case .unknown:
            return "unknown"
        case .networkLoad:
            return "network-load"
        case .serverPush:
            return "server-push"
        case .localCache:
            return "local-cache"
        @unknown default:
            return "unknown"
        }
    }
    
}
