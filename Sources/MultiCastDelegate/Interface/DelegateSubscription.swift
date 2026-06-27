//
//  DelegateSubscription.swift
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

/// Manages a collection of delegate subscribers and their associated dispatch queues.
///
/// Implementations are responsible for:
/// - Storing subscribers, typically as **weak references** to avoid retain cycles.
/// - Mapping each subscriber to the `DispatchQueue` on which it should receive callbacks.
///
/// The library ships ``DelegateSubscriptionHandle`` as the default concrete implementation.
/// You can provide your own if you need custom storage semantics (e.g., strong references
/// or a different threading model).
///
/// ## Design Notes
/// - **Class-only (`AnyObject`)**: A subscription store holds shared mutable state
///   (the subscriber list and queue map). Conformers must be reference types so the
///   same store backs every read and write — a value-type implementation would diverge
///   on each copy and break the multicaster's invariants.
/// - **Existential-based**: This protocol operates on `any MultiCastDelegate` so a single
///   subscription store can hold heterogeneous delegate types. Type-safe access is
///   provided by ``DelegateMultiCasting``, which bridges its generic `Delegate`
///   associated type to these methods automatically.
public protocol DelegateSubscription: AnyObject, Sendable {

    /// All currently live subscribers.
    ///
    /// Implementations that use weak storage should filter out deallocated references
    /// so this array only contains reachable objects.
    var subscribers: [any MultiCastDelegate] { get }

    /// Registers a subscriber to receive delegate callbacks on the specified queue.
    ///
    /// If the subscriber is already registered, the implementation should update
    /// its associated queue to `queue`.
    ///
    /// - Parameters:
    ///   - subscriber: The delegate to register.
    ///   - queue: The dispatch queue on which the subscriber will receive callbacks.
    func subscribe(_ subscriber: any MultiCastDelegate, receive queue: DispatchQueue)

    /// Removes a previously registered subscriber.
    ///
    /// If the subscriber is not currently registered, this method is a no-op.
    ///
    /// - Parameter subscriber: The delegate to remove.
    func unsubscribe(_ subscriber: any MultiCastDelegate)

    /// Returns the dispatch queue associated with the given subscriber.
    ///
    /// - Parameter subscriber: The delegate whose queue is requested.
    /// - Returns: The queue the subscriber was registered with, or `.main` if not found.
    func queue(for subscriber: any MultiCastDelegate) -> DispatchQueue
}
