//
//  DelegateSubscription.swift
//  UtilityKit
//
//  Created by kavi gevariya on 26/04/26.
//

import Foundation

/// Manages a collection of delegate subscribers and their associated dispatch queues.
///
/// Implementations are responsible for storing subscribers (typically as weak references)
/// and mapping each subscriber to the `DispatchQueue` on which it should receive callbacks.
public protocol DelegateSubscription: Sendable {

    /// All currently registered subscribers.
    var subscribers: [any DelegateSubscriber] { get }

    /// Registers a subscriber to receive delegate callbacks on the specified queue.
    /// - Parameters:
    ///   - subscriber: The delegate to register.
    ///   - queue: The dispatch queue on which the subscriber will receive callbacks.
    func subscribe(_ subscriber: any DelegateSubscriber, receive queue: DispatchQueue)

    /// Removes a previously registered subscriber. No-op if the subscriber is not registered.
    /// - Parameter subscriber: The delegate to remove.
    func unsubscribe(_ subscriber: any DelegateSubscriber)

    /// Returns the dispatch queue associated with the given subscriber.
    /// - Parameter subscriber: The delegate whose queue is requested.
    /// - Returns: The queue the subscriber was registered with, or `.main` if not found.
    func queue(for subscriber: any DelegateSubscriber) -> DispatchQueue
}
