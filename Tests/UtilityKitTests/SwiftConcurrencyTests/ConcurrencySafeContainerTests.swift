// Copyright (c) 2026 kaVi Gevariya (@kaVish2214)
//
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file, You can
// obtain one at https://mozilla.org/MPL/2.0/.
// SPDX-License-Identifier: MPL-2.0

import Testing
import Foundation
@testable import SwiftConcurrency

@Suite("ConcurrencySafeContainer")
struct ConcurrencySafeContainerTests {

    // MARK: - Initialization

    @Test("init(_:) seeds the container with a Sendable value")
    func initialStateSeed() {
        let container = ConcurrencySafeContainer<Int>(7)

        let value = container.withLock { $0 }

        #expect(value == 7)
    }

    @Test("init(_:) seeds the container with non-Sendable state")
    func initialStateUnchecked() {
        let container = ConcurrencySafeContainer<NonSendableBox>(NonSendableBox(11))

        let value = container.withLockUnchecked { $0.value }

        #expect(value == 11)
    }

    // MARK: - withLock

    @Test("withLock mutates the state in place")
    func withLockMutates() {
        let container = ConcurrencySafeContainer<Int>(0)

        container.withLock { state in
            state += 1
        }
        container.withLock { state in
            state += 2
        }

        #expect(container.withLock { $0 } == 3)
    }

    @Test("withLock returns the closure's value")
    func withLockReturns() {
        let container = ConcurrencySafeContainer<String>("hello")

        let length = container.withLock { state -> Int in
            state.count
        }

        #expect(length == 5)
    }

    @Test("withLock rethrows errors thrown by the body")
    func withLockRethrows() {
        struct Boom: Error, Equatable {}
        let container = ConcurrencySafeContainer<Int>(0)

        #expect(throws: Boom.self) {
            try container.withLock { _ in
                throw Boom()
            }
        }
    }

    // MARK: - withLockUnchecked

    @Test("withLockUnchecked mutates non-Sendable state")
    func withLockUncheckedMutates() {
        let container = ConcurrencySafeContainer<NonSendableBox>(NonSendableBox(0))

        container.withLockUnchecked { box in
            box.value = 42
        }

        let value = container.withLockUnchecked { $0.value }
        #expect(value == 42)
    }

    @Test("withLockUnchecked can return non-Sendable references")
    func withLockUncheckedReturnsReference() {
        let container = ConcurrencySafeContainer<NonSendableBox>(NonSendableBox(99))

        let box = container.withLockUnchecked { $0 }

        #expect(box.value == 99)
    }

    @Test("withLockUnchecked rethrows errors thrown by the body")
    func withLockUncheckedRethrows() {
        struct Boom: Error, Equatable {}
        let container = ConcurrencySafeContainer<Int>(0)

        #expect(throws: Boom.self) {
            try container.withLockUnchecked { _ in
                throw Boom()
            }
        }
    }

    // MARK: - Thread Safety

    @Test("Concurrent increments from many tasks all land")
    func concurrentIncrements() async {
        let container = ConcurrencySafeContainer<Int>(0)
        let iterations = 1_000

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    container.withLock { $0 += 1 }
                }
            }
        }

        #expect(container.withLock { $0 } == iterations)
    }

    @Test("Concurrent reads and writes don't crash or corrupt state")
    func concurrentReadWrite() async {
        let container = ConcurrencySafeContainer<[Int]>([])
        let writers = 200

        await withTaskGroup(of: Void.self) { group in
            for index in 0..<writers {
                group.addTask {
                    container.withLock { array in
                        array.append(index)
                    }
                }
                group.addTask {
                    _ = container.withLock { $0.count }
                }
            }
        }

        let final = container.withLock { $0 }
        #expect(final.count == writers)
        #expect(Set(final).count == writers)
    }

    @Test("Concurrent dictionary writes preserve every key")
    func concurrentDictionaryWrites() async {
        let container = ConcurrencySafeContainer<[String: Int]>([:])
        let keys = (0..<500).map { "key-\($0)" }

        await withTaskGroup(of: Void.self) { group in
            for key in keys {
                group.addTask {
                    container.withLock { dict in
                        dict[key, default: 0] += 1
                    }
                }
            }
        }

        let snapshot = container.withLock { $0 }
        #expect(snapshot.count == keys.count)
        #expect(snapshot.values.allSatisfy { $0 == 1 })
    }

    // MARK: - Value-Type State

    @Test("Container holds independent state per instance")
    func independentInstances() {
        let containerA = ConcurrencySafeContainer<Int>(0)
        let containerB = ConcurrencySafeContainer<Int>(0)

        containerA.withLock { $0 = 10 }
        containerB.withLock { $0 = 20 }

        #expect(containerA.withLock { $0 } == 10)
        #expect(containerB.withLock { $0 } == 20)
    }
}
