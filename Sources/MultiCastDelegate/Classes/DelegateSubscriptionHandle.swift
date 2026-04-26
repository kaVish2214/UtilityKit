//
//  DelegateSubscriptionHandle.swift
//  UtilityKit
//
//  Created by kavi gevariya on 26/04/26.
//

import Foundation

/// A thread-safe, concrete implementation of ``DelegateSubscription`` that stores
/// subscribers as **weak references**.
///
/// ### Storage
/// - `NSHashTable.weakObjects()` — subscribers are automatically zeroed out when
///   deallocated; ``subscribers`` filters these entries so callers only see live objects.
/// - `NSMapTable.weakToStrongObjects()` — maps each subscriber to its callback
///   `DispatchQueue`. Entries are removed when the subscriber is deallocated.
///
/// ### Thread Safety
/// All reads and writes are serialized through an `NSLock`, making it safe to
/// subscribe, unsubscribe, and iterate from any thread or queue concurrently.
///
/// ### Typical Usage
/// You rarely interact with this class directly. Instead, declare it as the
/// ``DelegateMultiCasting/delegates`` property and let the protocol's default
/// implementations handle the rest:
/// ```swift
/// final class MyService: DelegateMultiCasting, @unchecked Sendable {
///     typealias Delegate = any MyDelegate
///     let delegates: any DelegateSubscription = DelegateSubscriptionHandle()
/// }
/// ```
public final class DelegateSubscriptionHandle: DelegateSubscription, @unchecked Sendable {

    // MARK: - Properties

    private let lock = NSLock()
    private let delegateStorage: NSHashTable<AnyObject> = .weakObjects()
    private let queueStorage: NSMapTable<AnyObject, DispatchQueue> = .weakToStrongObjects()

    // MARK: - Initializer

    public init() {}

    // MARK: - DelegateSubscription

    public var subscribers: [any MultiCastDelegate] {
        lock.lock()
        defer { lock.unlock() }
        return delegateStorage.allObjects.compactMap { $0 as? (any MultiCastDelegate) }
    }

    public func subscribe(_ subscriber: any MultiCastDelegate, receive queue: DispatchQueue) {
        lock.lock()
        defer { lock.unlock() }
        delegateStorage.add(subscriber)
        queueStorage.setObject(queue, forKey: subscriber)
    }

    public func unsubscribe(_ subscriber: any MultiCastDelegate) {
        lock.lock()
        defer { lock.unlock() }
        delegateStorage.remove(subscriber)
        queueStorage.removeObject(forKey: subscriber)
    }

    public func queue(for subscriber: any MultiCastDelegate) -> DispatchQueue {
        lock.lock()
        defer { lock.unlock() }
        return queueStorage.object(forKey: subscriber) ?? .main
    }
}
