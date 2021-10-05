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

/// Directives that define whether a response/request can be cached,
/// where it may be cached, and whether it must be validated with
/// the origin server before caching.
///
/// See <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control>
///
/// - `maxAge`: The maximum amount of time a resource is considered fresh.
///             Unlike Expires, this directive is relative to the time of the request.
/// - `maxStale`: Indicates the client will accept a stale response.
///               An optional value in seconds indicates the upper limit of staleness the client will accept.
/// - `minFresh` Indicates the client wants a response that will still be fresh
///              for at least the specified number of seconds.
/// - `noCache`: The response may be stored by any cache, even if the response
///              is normally non-cacheable. However, the stored response
///              MUST always go through validation with the origin server
///              first before using it, therefore, you cannot use
///              no-cache in-conjunction with immutable.
///              If you mean to not store the response in any cache, use no-store instead.
///              This directive is not effective in preventing caches from storing your response.
/// - `noStore`:
/// - `noTransform`: An intermediate cache or proxy cannot edit the response body,
///                  Content-Encoding, Content-Range, or Content-Type.
///                  It therefore forbids a proxy or browser feature,
///                  such as Google’s Web Light, from converting images to minimize data
///                  for a cache store or slow connection.
/// - `onlyIfCached`: Set by the client to indicate "do not use the network" for the response.
///                   The cache should either respond using a stored response, or respond with
///                   a 504 status code.
///                   Conditional headers such as If-None-Match should not be set.
///                   There is no effect if only-if-cached is set by a server as part of a response.
public enum HTTPCacheControl {
    case maxAge(seconds: TimeInterval)
    case maxStale(seconds: TimeInterval?)
    case minFresh(seconds: TimeInterval?)
    case noCache
    case noStore
    case noTransform
    case onlyIfCached
    
    public var headerValue: String {
        switch self {
        case .maxAge(seconds: let seconds):
            return "max-age=\(Int(seconds))"
        case .maxStale(seconds: let seconds):
            guard let seconds = seconds else {
                return "max-stale"
            }
            
            return "max-stale=\(Int(seconds))"
        case .minFresh(seconds: let seconds):
            guard let seconds = seconds else {
                return "max-fresh"
            }
            
            return "min-fresh=\(Int(seconds))"
        case .noCache:
            return "no-cache"
        case .noStore:
            return "no-store"
        case .noTransform:
            return "no-transform"
        case .onlyIfCached:
            return "only-if-cached"
        }
    }
    
}
