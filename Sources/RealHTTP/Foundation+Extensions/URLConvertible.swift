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
//  Copyright ©2021 Immobiliare.it SpA.
//  Licensed under MIT License.
//

import Foundation

// MARK: - URLConvertible

/// Any type conform to `URLConvertible` protocol can be used to construct `URL`s
/// and therefore `URLRequest` instances.
public protocol URLConvertible {
    
    /// Returns a `URL` from the conforming instance.
    ///
    /// - Returns: The `URL` created from the instance.
    /// - Throws:  Any error thrown while creating the `URL`.
    func asURL() throws -> URL
    
}

// MARK: - String + URLConvertible

extension String: URLConvertible {
    
    /// Returns a `URL` if `self` can be used to initialize a `URL` instance, otherwise throws.
    ///
    /// - Returns: The `URL` initialized with `self`.
    /// - Throws:  Throw an exception if conversion fails.
    public func asURL() throws -> URL {
        guard let url = URL(string: self) else {
            throw HTTPError(.invalidURL)
        }

        return url
    }
    
}

// MARK: - URL + URLConvertible

extension URL: URLConvertible {
    
    /// Returns `self`.
    public func asURL() throws -> URL {
        self
    }
    
}


// MARK: - URLComponents + URLConvertible

extension URLComponents: URLConvertible {
    
    /// Returns a `URL` if the `self`'s `url` is not nil, otherwise throws.
    ///
    /// - Returns: The `URL` from the `url` property.
    /// - Throws:  An `AFError.invalidURL` instance.
    public func asURL() throws -> URL {
        guard let url = url else {
            throw HTTPError(.invalidURL)
        }

        return url
    }
    
}
