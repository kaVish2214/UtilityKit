//
//  ConcurrencySafeContainer.swift
//  UtilityKit
//
//  Created by kavi gevariya on 22/06/26.
//

import Foundation
import os

// MARK: - ConcurrencySafe container


public struct ConcurrencySafeContainer<State>: ConcurrencyContainerProtocol, @unchecked Sendable {

    private let backend: any ConcurrencyContainerProtocol<State>

    public init(uncheckedState initialState: sending State) {
        #if canImport(Synchronization)
        if #available(iOS 18.0, macOS 15.0, *) {
            self.backend = MutexBox<State>(uncheckedState: initialState)
            return
        }
        #endif
        if #available(iOS 16.0, macOS 13.0, *) {
            self.backend = OSAllocatedUnfairLock<State>(uncheckedState: initialState)
            return
        }
        self.backend = LegacyConcurrencySafe<State>(uncheckedState: initialState)
    }

    public func withLockUnchecked<R>(_ body: (inout State) throws -> R) rethrows -> R {
        try backend.withLockUnchecked(body)
    }

    public func withLock<R>(_ body: @Sendable (inout State) throws -> R) rethrows -> R where R: Sendable {
        try backend.withLock(body)
    }
}
