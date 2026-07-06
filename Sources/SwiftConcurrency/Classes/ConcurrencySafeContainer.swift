//
//  ConcurrencySafeContainer.swift
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

// MARK: - ConcurrencySafeContainer

/// A drop-in, OS-adaptive ``ConcurrencyContainerProtocol`` that protects a single
/// piece of mutable state behind the fastest synchronization primitive available on
/// the running OS.
///
/// `ConcurrencySafeContainer` is the default concrete implementation shipped with
/// the `SwiftConcurrency` product. It picks its backend at runtime:
///
/// | Backend                            | Selected on                 | Why                                                |
/// |------------------------------------|-----------------------------|----------------------------------------------------|
/// | `Mutex` (Swift `Synchronization`)  | iOS 18+ / macOS 15+         | Fastest; non-blocking; native value-type semantics.|
/// | `OSAllocatedUnfairLock`            | iOS 16+ / macOS 13+         | Fast OS-allocated unfair lock.                     |
/// | `NSLock` (`LegacyConcurrencySafe`) | All supported deployments   | Universal fallback.                                |
///
/// The selection is **transparent** — call sites see only the protocol surface
/// (``withLockUnchecked(_:)`` / ``withLock(_:)``) and never need to branch on OS
/// availability themselves.
///
/// ## Sendable Synthesis
/// The struct doesn't need `@unchecked Sendable`. `ConcurrencyContainerProtocol`
/// refines `Sendable`, so `any ConcurrencyContainerProtocol<State>` — the only
/// stored property's type — is `Sendable`. With every stored field `Sendable`,
/// the compiler synthesizes `Sendable` conformance for the struct automatically,
/// even when `State` itself is not `Sendable` (the value lives inside the backend's
/// lock, never directly on the struct).
///
/// ## Usage
/// ```swift
/// // Sendable state.
/// let counter = ConcurrencySafeContainer<Int>(0)
/// counter.withLock { $0 += 1 }
/// let snapshot = counter.withLock { $0 }
///
/// // Non-Sendable state — same entry point, ownership transfers in.
/// let cache = ConcurrencySafeContainer<NSMutableDictionary>(NSMutableDictionary())
/// cache.withLockUnchecked { dict in
///     dict["key"] = "value"
/// }
/// ```
public struct ConcurrencySafeContainer<State>: ConcurrencyContainerProtocol {

    /// The OS-selected backend doing the actual locking.
    private let backend: any ConcurrencyContainerProtocol<State>

    /// Creates a container holding `state`, choosing the best backend available on
    /// the current OS (`Mutex` → `OSAllocatedUnfairLock` → `NSLock`).
    ///
    /// - Parameter state: The starting value. Ownership is transferred into the
    ///   container.
    public init(_ state: sending State) {
        #if canImport(Synchronization)
        if #available(iOS 18.0, macOS 15.0, *) {
            self.backend = MutexBox<State>(state)
            return
        }
        #endif
        if #available(iOS 16.0, macOS 13.0, *) {
            self.backend = OSAllocatedUnfairLock<State>(state)
            return
        }
        self.backend = LegacyConcurrencySafe<State>(state)
    }

    /// Runs `body` with exclusive, mutable access to the protected state. Skips
    /// `Sendable` enforcement so non-`Sendable` values can be returned.
    ///
    /// Prefer ``withLock(_:)`` whenever the closure can be `@Sendable`.
    @discardableResult
    public func withLockUnchecked<R>(_ body: (inout State) throws -> R) rethrows -> R {
        try backend.withLockUnchecked(body)
    }

    /// Runs `body` with exclusive, mutable access to the protected state. Both the
    /// closure and its return value are required to be `Sendable`, so the compiler
    /// rules out non-`Sendable` aliasing leaking out of the lock.
    @discardableResult
    public func withLock<R>(_ body: @Sendable (inout State) throws -> R) rethrows -> R where R: Sendable {
        try backend.withLock(body)
    }
}
