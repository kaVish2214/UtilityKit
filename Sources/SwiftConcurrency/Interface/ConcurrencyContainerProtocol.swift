//
//  ConcurrencyContainerProtocol.swift
//  UtilityKit
//
//  Created by kavi gevariya on 22/06/26.
//

import Foundation


public protocol ConcurrencyContainerProtocol<State> {

    associatedtype State

    init(uncheckedState initialState: sending State)

    func withLockUnchecked<R>(_ body: (inout State) throws -> R) rethrows -> R

    func withLock<R>(_ body: @Sendable (inout State) throws -> R) rethrows -> R where R: Sendable
}

extension ConcurrencyContainerProtocol where State: Sendable {
    
    public init(initialState: State) {
        self.init(uncheckedState: initialState)
    }
}


