//
//  PrivateContainer.swift
//  UtilityKit
//
//  Copyright (c) 2026 kaVi Gevariya (@kaVish2214)
//
//  This Source Code Form is subject to the terms of the Mozilla Public License,
//  v. 2.0. If a copy of the MPL was not distributed with this file, You can
//  obtain one at https://mozilla.org/MPL/2.0/.
//  SPDX-License-Identifier: MPL-2.0
//

import Foundation
import os

#if canImport(Synchronization)
import Synchronization
#endif


// MARK: - OSAllocatedUnfairLock conformance (iOS 16+ / macOS 13+)

/// Plugs Apple's `OSAllocatedUnfairLock` straight into `ConcurrencyContainerProtocol`.
///
/// `OSAllocatedUnfairLock` already supplies `withLock` and `withLockUnchecked` with
/// the exact shapes the protocol requires, so those requirements are satisfied
/// implicitly. Its native init is labeled `init(uncheckedState:)`, however, while the
/// protocol requires an unlabeled `init(_:)` — so this extension adds a one-line
/// forwarder to bridge the label and complete the conformance.
@available(iOS 16.0, macOS 13.0, *)
extension OSAllocatedUnfairLock: ConcurrencyContainerProtocol {

    /// Bridges the protocol's unlabeled `init(_:)` to Apple's native
    /// `init(uncheckedState:)`.
    public init(_ state: sending State) {
        self.init(uncheckedState: state)
    }
}


// MARK: - Mutex backend (iOS 18+ / macOS 15+)

#if canImport(Synchronization)
/// Wraps Swift's `Mutex` (from the `Synchronization` framework) so it can satisfy
/// `ConcurrencyContainerProtocol`.
///
/// `Mutex` itself can't conform via an empty extension because it differs from the
/// protocol on several axes:
/// - It's `~Copyable`, while the protocol requires `Copyable` conformers.
/// - Its `withLock` body takes `(inout sending Value)` and supports typed throws +
///   `~Copyable` results, neither of which matches the protocol shape.
/// - It exposes no `withLockUnchecked` method.
///
/// This thin reference-type wrapper lifts the `~Copyable` constraint (a class
/// instance is freely copyable by reference) and re-exposes the `Mutex` API under the
/// protocol's signatures. It's `@unchecked Sendable` because all mutable state lives
/// inside the lock.
@available(iOS 18.0, macOS 15.0, *)
final class MutexBox<State>: ConcurrencyContainerProtocol, @unchecked Sendable {

    /// The wrapped `Mutex` doing the real synchronization.
    private let mutex: Mutex<State>

    /// Forwards to `Mutex.init(_:)`.
    init(_ state: sending State) {
        self.mutex = .init(state)
    }

    /// Forwards to `Mutex.withLock` without `Sendable` enforcement.
    func withLockUnchecked<R>(_ body: (inout sending State) throws -> R) rethrows -> R {
        try mutex.withLock { state in
            try body(&state)
        }
    }

    /// Forwards to `Mutex.withLock` with `Sendable` enforcement on the body and the
    /// return value.
    func withLock<R>(_ body: @Sendable (inout sending State) throws -> R) rethrows -> R where R: Sendable {
        try mutex.withLock { state in
            try body(&state)
        }
    }
}
#endif


// MARK: - NSLock backend (fallback)

/// Universal fallback backend backed by `NSLock`.
///
/// Used on OS versions older than the availability windows of `Mutex`
/// (iOS 18 / macOS 15) and `OSAllocatedUnfairLock` (iOS 16 / macOS 13). Slower than
/// the modern primitives, but available on every deployment target the package
/// supports. `@unchecked Sendable` because the lock serializes all access to `state`.
final class LegacyConcurrencySafe<State>: ConcurrencyContainerProtocol, @unchecked Sendable {

    /// The protected value.
    private var state: State

    /// The lock that serializes access to `state`.
    private let lock = NSLock()

    /// Stores the initial value. Transferred in via `sending`.
    init(_ state: sending State) {
        self.state = state
    }

    /// Acquires the lock, runs `body`, releases the lock.
    func withLockUnchecked<R>(_ body: (inout State) throws -> R) rethrows -> R {
        lock.lock()
        defer { lock.unlock() }
        return try body(&state)
    }

    /// Acquires the lock, runs `body`, releases the lock. Requires `body` and `R` to
    /// be `Sendable` so the lock contract is compile-time checked.
    func withLock<R>(_ body: @Sendable (inout State) throws -> R) rethrows -> R where R: Sendable {
        lock.lock()
        defer { lock.unlock() }
        return try body(&state)
    }
}
