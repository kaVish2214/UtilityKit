//
//  DelegateMultiCasting.swift
//  UtilityKit
//
//  Created by kavi gevariya on 26/04/26.
//

import Foundation

/// A protocol that enables one-to-many delegate communication.
///
/// Conforming types maintain a ``DelegateSubscription`` that stores subscribers and their
/// associated dispatch queues. Callbacks are delivered to every registered subscriber
/// on its designated queue via ``invoke(invocation:)``.
///
/// ### Usage
/// ```swift
/// protocol MyDelegate: DelegateSubscriber {
///     func didUpdate(value: Int)
/// }
///
/// final class MyService: DelegateMultiCasting {
///     typealias Delegate = MyDelegate
///     let delegates: any DelegateSubscription = DelegateSubscriptionHandle()
/// }
///
/// // Subscribe
/// service.subscribeDelegate(observer, receive: .main)
///
/// // Broadcast
/// service.invoke { $0?.didUpdate(value: 42) }
/// ```
public protocol DelegateMultiCasting: Sendable {

    associatedtype Delegate: DelegateSubscriber

    /// The subscription managing registered delegates and their dispatch queues.
    var delegates: any DelegateSubscription { get }

    /// Broadcasts an invocation to all registered delegates.
    ///
    /// Each subscriber receives the callback on the queue it was registered with.
    /// The closure receives an optional `Delegate` because subscribers are held weakly
    /// and may have been deallocated.
    /// - Parameter invocation: A closure called once per subscriber.
    func invoke(invocation: @escaping @Sendable (Delegate?) -> ())
}

extension DelegateMultiCasting {

    public func invoke(invocation: @escaping @Sendable (Delegate?) -> ()) {
        for delegate in delegates.subscribers.reversed() {
            delegates.queue(for: delegate).async { [weak delegate] in
                invocation(delegate as? Delegate)
            }
        }
    }

    /// Registers a delegate to receive callbacks on the specified queue.
    /// - Parameters:
    ///   - delegate: The delegate to register.
    ///   - queue: The dispatch queue on which the delegate will receive callbacks.
    public func subscribeDelegate(_ delegate: Delegate, receive queue: DispatchQueue) {
        delegates.subscribe(delegate, receive: queue)
    }

    /// Removes a previously registered delegate.
    /// - Parameter delegate: The delegate to remove.
    public func unsubscribeDelegate(_ delegate: Delegate) {
        delegates.unsubscribe(delegate)
    }
}
