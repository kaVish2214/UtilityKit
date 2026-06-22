//
//  PrivateContainer.swift
//  UtilityKit
//
//  Created by kavi gevariya on 22/06/26.
//

import Foundation
import os

#if canImport(Synchronization)
import Synchronization
#endif


// MARK: - OSAllocatedUnfairLock conformance (iOS 16+ / macOS 13+)

@available(iOS 16.0, *)
extension OSAllocatedUnfairLock: ConcurrencyContainerProtocol {}


// MARK: - Mutex backend (iOS 18+ / macOS 15+)

#if canImport(Synchronization)
@available(iOS 18.0, macOS 15.0, *)
final class MutexBox<State>: ConcurrencyContainerProtocol, @unchecked Sendable {

    private let mutex: Mutex<State>

    init(uncheckedState initialState: sending State) {
        self.mutex = .init(initialState)
    }

    func withLockUnchecked<R>(_ body: (inout sending State) throws -> R) rethrows -> R {
        try mutex.withLock { state in
            try body(&state)
        }
    }

    func withLock<R>(_ body: @Sendable (inout sending State) throws -> R) rethrows -> R where R: Sendable {
        try mutex.withLock { state in
            try body(&state)
        }
    }
}
#endif


// MARK: - NSLock backend (fallback)

final class LegacyConcurrencySafe<State>: ConcurrencyContainerProtocol, @unchecked Sendable {

    private var state: State
    private let lock = NSLock()

    init(uncheckedState initialState: sending State) {
        self.state = initialState
    }

    func withLockUnchecked<R>(_ body: (inout State) throws -> R) rethrows -> R {
        lock.lock()
        defer { lock.unlock() }
        return try body(&state)
    }

    func withLock<R>(_ body: @Sendable (inout State) throws -> R) rethrows -> R where R: Sendable {
        lock.lock()
        defer { lock.unlock() }
        return try body(&state)
    }
}
