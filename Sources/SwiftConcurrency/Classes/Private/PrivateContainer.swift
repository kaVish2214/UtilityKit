//
//  PrivateContainer.swift
//  UtilityKit
//
//  Created by kavi gevariya on 22/06/26.
//

import Foundation
import os

#if canImport(Synchronization)
import Synchronization
#endif


// MARK: - OSAllocatedUnfairLock conformance (iOS 16+ / macOS 13+)

/// Plugs Apple's `OSAllocatedUnfairLock` straight into `ConcurrencyContainerProtocol`.
/// `OSAllocatedUnfairLock` already exposes `init(uncheckedState:)`, `withLock`, and
/// `withLockUnchecked` with the exact shapes the protocol requires, so the conformance
/// is satisfied by an empty extension.
@available(iOS 16.0, macOS 13.0, *)
extension OSAllocatedUnfairLock: ConcurrencyContainerProtocol {
    
    public init(_ state: sending State) {
        self.init(uncheckedState: state)
    }
}


// MARK: - Mutex backend (iOS 18+ / macOS 15+)

#if canImport(Synchronization)
/// Wraps Swift's `Mutex` (from the `Synchronization` framework) so it can satisfy
/// `ConcurrencyContainerProtocol`. `Mutex` is a value type and its `withLock` takes
/// `(inout sending Value)`, so this thin class re-exposes it under the protocol's
/// signature.
@available(iOS 18.0, macOS 15.0, *)
final class MutexBox<State>: ConcurrencyContainerProtocol, @unchecked Sendable {

    private let mutex: Mutex<State>

    init(_ state: sending State) {
        self.mutex = .init(state)
    }

    func withLockUnchecked<R>(_ body: (inout sending State) throws -> R) rethrows -> R {
        try mutex.withLock { state in
            try body(&state)
        }
    }

    func withLock<R>(_ body: @Sendable (inout sending State) throws -> R) rethrows -> R where R: Sendable {
        try mutex.withLock { state in
            try body(&state)
        }
    }
}
#endif


// MARK: - NSLock backend (fallback)

/// Universal fallback backend backed by `NSLock`. Used on OS versions older than the
/// availability windows of `Mutex` and `OSAllocatedUnfairLock`. Slower than the
/// modern primitives, but available everywhere the package supports.
final class LegacyConcurrencySafe<State>: ConcurrencyContainerProtocol, @unchecked Sendable {

    private var state: State
    private let lock = NSLock()

    init(_ state: sending State) {
        self.state = state
    }

    func withLockUnchecked<R>(_ body: (inout State) throws -> R) rethrows -> R {
        lock.lock()
        defer { lock.unlock() }
        return try body(&state)
    }

    func withLock<R>(_ body: @Sendable (inout State) throws -> R) rethrows -> R where R: Sendable {
        lock.lock()
        defer { lock.unlock() }
        return try body(&state)
    }
}
