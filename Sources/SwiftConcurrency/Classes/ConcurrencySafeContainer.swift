//
//  ConcurrencySafeContainer.swift
//  UtilityKit
//
//  Created by kavi gevariya on 22/06/26.
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
/// ## Why `@unchecked Sendable`
/// The wrapper itself doesn't expose any mutable state; all mutation flows through the
/// backend, which is responsible for thread safety. `@unchecked Sendable` lets the
/// container be passed across isolation boundaries without ceremony, while the lock
/// guarantees soundness.
///
/// ## Usage
/// ```swift
/// // Sendable state.
/// let counter = ConcurrencySafeContainer<Int>(uncheckedState: 0)
/// counter.withLock { $0 += 1 }
/// let snapshot = counter.withLock { $0 }
///
/// // Non-Sendable state — same entry point, ownership transfers in.
/// let cache = ConcurrencySafeContainer<NSMutableDictionary>(uncheckedState: NSMutableDictionary())
/// cache.withLockUnchecked { dict in
///     dict["key"] = "value"
/// }
/// ```
public struct ConcurrencySafeContainer<State>: ConcurrencyContainerProtocol, @unchecked Sendable {

    /// The OS-selected backend doing the actual locking.
    private let backend: any ConcurrencyContainerProtocol<State>

    /// Creates a container holding `initialState`, choosing the best backend
    /// available on the current OS (`Mutex` → `OSAllocatedUnfairLock` → `NSLock`).
    ///
    /// - Parameter initialState: The starting value. Ownership is transferred into
    ///   the container.
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
    public func withLockUnchecked<R>(_ body: (inout State) throws -> R) rethrows -> R {
        try backend.withLockUnchecked(body)
    }

    /// Runs `body` with exclusive, mutable access to the protected state. Both the
    /// closure and its return value are required to be `Sendable`, so the compiler
    /// rules out non-`Sendable` aliasing leaking out of the lock.
    public func withLock<R>(_ body: @Sendable (inout State) throws -> R) rethrows -> R where R: Sendable {
        try backend.withLock(body)
    }
}
