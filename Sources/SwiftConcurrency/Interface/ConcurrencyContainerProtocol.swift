//
//  ConcurrencyContainerProtocol.swift
//  UtilityKit
//
//  Created by kavi gevariya on 22/06/26.
//

import Foundation


/// A unified interface for a synchronized box that protects a single piece of mutable
/// state behind a lock.
///
/// `ConcurrencyContainerProtocol` is intentionally narrow: it owns exactly one value of
/// type ``State`` and exposes two ways to mutate it under exclusive access —
/// ``withLockUnchecked(_:)`` (no `Sendable` checking) and ``withLock(_:)`` (full
/// `Sendable` enforcement on both the closure and its return value).
///
/// The package ships ``ConcurrencySafeContainer`` as the default concrete implementation.
/// It transparently picks the best backend available on the current OS:
///
/// | Backend                            | Available on                | Notes                                              |
/// |------------------------------------|-----------------------------|----------------------------------------------------|
/// | `Mutex` (Synchronization)          | iOS 18+ / macOS 15+         | Preferred when available — fast and non-blocking.  |
/// | `OSAllocatedUnfairLock`            | iOS 16+ / macOS 13+         | OS-allocated unfair lock.                          |
/// | `NSLock` (`LegacyConcurrencySafe`) | All supported deployments   | Fallback for older OS versions.                    |
///
/// You normally use ``ConcurrencySafeContainer`` directly — but the protocol exists so
/// callers can substitute their own backend (e.g., a recursive lock or actor shim)
/// without changing call sites.
///
/// ## Usage
/// ```swift
/// // Sendable state — pass directly.
/// let counter = ConcurrencySafeContainer<Int>(0)
///
/// counter.withLock { state in
///     state += 1
/// }
///
/// let snapshot = counter.withLock { state in state }
///
/// // Non-Sendable state — same entry point, ownership transfers in.
/// let cache = ConcurrencySafeContainer<NSMutableDictionary>(NSMutableDictionary())
/// cache.withLockUnchecked { dict in
///     dict["key"] = "value"
/// }
/// ```
///
/// ## Choosing Between `withLock` and `withLockUnchecked`
/// - Use ``withLock(_:)`` whenever you can — the compiler enforces `Sendable` for
///   both the body closure and its return value, preventing data races at the type
///   level.
/// - Use ``withLockUnchecked(_:)`` only when you must mutate or extract a value that
///   isn't `Sendable` (e.g., a legacy class). You become responsible for guaranteeing
///   no aliasing escapes the closure.
///
/// ## Why `init(_:)` Takes `sending State`
/// The initializer accepts the initial state as `sending`, so callers **transfer**
/// ownership of the value into the container. Once constructed, the value is only
/// reachable through ``withLockUnchecked(_:)`` or ``withLock(_:)``, which is what
/// makes the container a safe concurrency boundary even when `State` isn't
/// `Sendable`. Passing a `Sendable` value through this initializer is equally
/// safe — `sending` accepts any value the type system can prove is unique at the
/// call site, which `Sendable` values trivially are.
///
/// ## Why the Protocol Refines `Sendable`
/// Every conformer is required to be `Sendable` so the container can cross isolation
/// boundaries (be captured by tasks, stored in actors, passed between threads)
/// without ceremony. The lock inside each conformer is what makes that safe; refining
/// the protocol on `Sendable` simply surfaces that contract at the type level so the
/// compiler can enforce it everywhere a `ConcurrencyContainerProtocol` is used.
public protocol ConcurrencyContainerProtocol<State>: Sendable {

    /// The type of value held under the lock.
    associatedtype State

    /// Creates a container holding `state`.
    ///
    /// Marked `sending` so callers transfer ownership of the value into the container.
    /// Once constructed, the state can only be accessed through ``withLockUnchecked(_:)``
    /// or ``withLock(_:)``.
    ///
    /// - Parameter state: The starting value. Ownership is transferred into the
    ///   container.
    init(_ state: sending State)

    /// Runs `body` with exclusive, mutable access to the protected state, without
    /// enforcing `Sendable` on the closure or return value.
    ///
    /// Use this overload only when you must return or mutate a non-`Sendable` value
    /// (e.g., a UIKit object or a legacy class). You become responsible for ensuring
    /// no aliasing escapes the closure.
    ///
    /// - Parameter body: A closure that receives exclusive mutable access to the state.
    /// - Returns: Whatever `body` returns.
    func withLockUnchecked<R>(_ body: (inout State) throws -> R) rethrows -> R

    /// Runs `body` with exclusive, mutable access to the protected state. Both the
    /// closure and its return value must be `Sendable`, so the compiler guarantees no
    /// non-`Sendable` reference escapes the lock.
    ///
    /// Prefer this over ``withLockUnchecked(_:)`` whenever it compiles.
    ///
    /// - Parameter body: A `@Sendable` closure that receives exclusive mutable access
    ///   to the state.
    /// - Returns: The closure's `Sendable` return value.
    func withLock<R>(_ body: @Sendable (inout State) throws -> R) rethrows -> R where R: Sendable
}
