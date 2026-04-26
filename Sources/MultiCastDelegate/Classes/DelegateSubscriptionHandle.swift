//
//  DelegateSubscriptionHandle.swift
//  UtilityKit
//
//  Created by kavi gevariya on 26/04/26.
//

import Foundation

/// A thread-safe, concrete implementation of ``DelegateSubscription`` that stores subscribers
/// as weak references.
///
/// Uses `NSHashTable.weakObjects()` so subscribers are automatically removed when deallocated,
/// and `NSMapTable` to associate each subscriber with its callback dispatch queue.
///
/// All access is serialized through an internal lock to ensure safe concurrent usage
/// from multiple threads.
public final class DelegateSubscriptionHandle: DelegateSubscription, @unchecked Sendable {

    // MARK: - Properties

    private let lock = NSLock()
    private let delegateStorage: NSHashTable<AnyObject> = .weakObjects()
    private let queueStorage: NSMapTable<AnyObject, DispatchQueue> = .weakToStrongObjects()

    // MARK: - Initializer

    public init() {}

    // MARK: - DelegateSubscription

    public var subscribers: [any DelegateSubscriber] {
        lock.lock()
        defer { lock.unlock() }
        return delegateStorage.allObjects.compactMap { $0 as? (any DelegateSubscriber) }
    }

    public func subscribe(_ subscriber: any DelegateSubscriber, receive queue: DispatchQueue) {
        lock.lock()
        defer { lock.unlock() }
        delegateStorage.add(subscriber)
        queueStorage.setObject(queue, forKey: subscriber)
    }

    public func unsubscribe(_ subscriber: any DelegateSubscriber) {
        lock.lock()
        defer { lock.unlock() }
        delegateStorage.remove(subscriber)
        queueStorage.removeObject(forKey: subscriber)
    }

    public func queue(for subscriber: any DelegateSubscriber) -> DispatchQueue {
        lock.lock()
        defer { lock.unlock() }
        return queueStorage.object(forKey: subscriber) ?? .main
    }
}
