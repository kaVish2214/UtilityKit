//
//  DelegateMultiCasting.swift
//  UtilityKit
//
//  Created by kavi gevariya on 26/04/26.
//

import Foundation

/// A protocol that enables type-safe, one-to-many delegate communication.
///
/// Conforming types maintain a ``DelegateSubscription`` that stores subscribers
/// as weak references along with their associated dispatch queues. Callbacks are
/// broadcast to every live subscriber on its designated queue via ``invoke(invocation:)``.
///
/// Default implementations for ``subscribeDelegate(_:receive:)``,
/// ``unsubscribeDelegate(_:)``, and ``invoke(invocation:)`` are provided
/// automatically — conforming types only need to declare the ``delegates`` property.
///
/// ## Defining a Delegate Protocol
/// ```swift
/// protocol MyDelegate: MultiCastDelegate {
///     func didUpdate(value: Int)
/// }
/// ```
///
/// ## Creating a Multicaster
/// ```swift
/// final class MyService: DelegateMultiCasting, @unchecked Sendable {
///     typealias Delegate = any MyDelegate
///     let delegates: any DelegateSubscription = DelegateSubscriptionHandle()
/// }
/// ```
///
/// ## Subscribing and Broadcasting
/// ```swift
/// let service = MyService()
///
/// // Register an observer on the main queue.
/// service.subscribeDelegate(observer, receive: .main)
///
/// // Broadcast to all registered delegates.
/// service.invoke { $0?.didUpdate(value: 42) }
///
/// // Unregister when no longer needed.
/// service.unsubscribeDelegate(observer)
/// ```
///
/// ## Topics
/// ### Managing Subscribers
/// - ``subscribeDelegate(_:receive:)``
/// - ``unsubscribeDelegate(_:)``
///
/// ### Broadcasting
/// - ``invoke(invocation:)``
public protocol DelegateMultiCasting: Sendable {

    /// The concrete delegate type that subscribers conform to.
    associatedtype Delegate: Sendable

    /// The subscription managing registered delegates and their dispatch queues.
    var delegates: any DelegateSubscription { get }

    /// Registers a delegate to receive callbacks on the specified queue.
    ///
    /// The delegate is stored as a weak reference; if it is deallocated,
    /// it is automatically removed from the subscriber list.
    ///
    /// - Parameters:
    ///   - delegate: The delegate to register. Must conform to ``MultiCastDelegate``.
    ///   - queue: The dispatch queue on which the delegate will receive callbacks.
    func subscribeDelegate(_ delegate: Delegate, receive queue: DispatchQueue)

    /// Removes a previously registered delegate.
    ///
    /// If the delegate is not currently registered, this method is a no-op.
    ///
    /// - Parameter delegate: The delegate to remove.
    func unsubscribeDelegate(_ delegate: Delegate)

    /// Broadcasts an invocation to all registered delegates.
    ///
    /// Each subscriber receives the callback asynchronously on the queue it was
    /// registered with. The closure receives an optional because subscribers are
    /// held as weak references and may have been deallocated between enumeration
    /// and delivery.
    ///
    /// - Parameter invocation: A closure called once per subscriber.
    func invoke(invocation: @escaping @Sendable (Delegate?) -> ())
}

// MARK: - Default Implementations

extension DelegateMultiCasting {

    /// Default: forwards to ``DelegateSubscription/subscribe(_:receive:)``
    /// after bridging `Delegate` to `any MultiCastDelegate`.
    public func subscribeDelegate(_ delegate: Delegate, receive queue: DispatchQueue) {
        guard let delegate = delegate as? any MultiCastDelegate else { return }
        delegates.subscribe(delegate, receive: queue)
    }

    /// Default: forwards to ``DelegateSubscription/unsubscribe(_:)``
    /// after bridging `Delegate` to `any MultiCastDelegate`.
    public func unsubscribeDelegate(_ delegate: Delegate) {
        guard let delegate = delegate as? any MultiCastDelegate else { return }
        delegates.unsubscribe(delegate)
    }

    /// Default: iterates ``DelegateSubscription/subscribers`` in reverse order and
    /// dispatches `invocation` asynchronously on each subscriber's registered queue.
    public func invoke(invocation: @escaping @Sendable (Delegate?) -> ()) {
        for delegate in delegates.subscribers.reversed() {
            delegates.queue(for: delegate).async { [weak delegate] in
                invocation(delegate as? Delegate)
            }
        }
    }
}
