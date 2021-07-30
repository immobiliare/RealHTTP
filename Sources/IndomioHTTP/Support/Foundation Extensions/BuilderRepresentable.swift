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

public protocol BuilderRepresentable {

    /// Configuration handler callback
    typealias Builder = (Self) -> Self
    
}

// MARK: - Methods for ValueType

extension BuilderRepresentable {

    @inlinable
    public func with<T>(_ keyPath: WritableKeyPath<Self, T>, _ value: T) -> Self {
        var result = self
        result[keyPath: keyPath] = value
        return result
    }

    @inlinable
    public func map<T>(_ keyPath: WritableKeyPath<Self, T>, _ transform: (T) throws -> T) rethrows -> Self {
        var result = self
        result[keyPath: keyPath] = try transform(result[keyPath: keyPath])
        return result
    }
}

// MARK: - Methods for ReferenceType

extension BuilderRepresentable {
    
    public func with<T>(_ keyPath: ReferenceWritableKeyPath<Self, T>, _ value: T) -> Self {
        self[keyPath: keyPath] = value
        return self
    }
    
    public func map<T>(_ keyPath: ReferenceWritableKeyPath<Self, T>, _ transform: (T) throws -> T) rethrows -> Self {
        self[keyPath: keyPath] = try transform(self[keyPath: keyPath])
        return self
    }
}
