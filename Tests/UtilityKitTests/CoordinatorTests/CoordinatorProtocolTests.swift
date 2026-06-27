// Copyright (c) 2026 kaVi Gevariya (@kaVish2214)
//
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file, You can
// obtain one at https://mozilla.org/MPL/2.0/.
// SPDX-License-Identifier: MPL-2.0

import Testing
import Foundation
@testable import Coordinator

@Suite("CoordinatorProtocol")
struct CoordinatorProtocolTests {

    // MARK: - initialize(with:)

    @Test("initialize binds the view delegate")
    func initializeBindsDelegate() {
        let coordinator = MockCoordinator()
        let delegate = MockViewDelegate()

        coordinator.initialize(with: delegate)

        #expect(coordinator.viewDelegate === delegate)
    }

    @Test("Calling initialize again replaces the previous delegate")
    func initializeReplacesDelegate() {
        let coordinator = MockCoordinator()
        let firstDelegate = MockViewDelegate()
        let secondDelegate = MockViewDelegate()

        coordinator.initialize(with: firstDelegate)
        coordinator.initialize(with: secondDelegate)

        #expect(coordinator.viewDelegate === secondDelegate)
        #expect(coordinator.viewDelegate !== firstDelegate)
    }

    // MARK: - Weak Reference

    @Test("View delegate is held weakly — it deallocates when external ref drops")
    func viewDelegateIsWeak() {
        let coordinator = MockCoordinator()

        autoreleasepool {
            let delegate = MockViewDelegate()
            coordinator.initialize(with: delegate)
            #expect(coordinator.viewDelegate != nil)
        }

        #expect(coordinator.viewDelegate == nil)
    }

    // MARK: - Independence

    @Test("Two coordinators each track their own view delegate")
    func independentCoordinators() {
        let coordinatorA = MockCoordinator()
        let coordinatorB = MockCoordinator()
        let delegateA = MockViewDelegate()
        let delegateB = MockViewDelegate()

        coordinatorA.initialize(with: delegateA)
        coordinatorB.initialize(with: delegateB)

        #expect(coordinatorA.viewDelegate === delegateA)
        #expect(coordinatorB.viewDelegate === delegateB)
    }

    // MARK: - Round-Trip Through View Delegate

    @Test("Business logic on the coordinator routes through the view delegate")
    func businessLogicRoutesToDelegate() {
        let coordinator = MockCoordinator()
        let delegate = MockViewDelegate()
        coordinator.initialize(with: delegate)

        coordinator.performBusinessLogic()
        coordinator.performBusinessLogic()
        coordinator.performBusinessLogic()

        #expect(coordinator.businessLogicInvocations == 3)
        #expect(delegate.navigationCount == 3)
    }

    @Test("Calls with a nil view delegate do not crash")
    func nilDelegateIsSafe() {
        let coordinator = MockCoordinator()

        // No initialize() call — viewDelegate is nil.
        coordinator.performBusinessLogic()

        #expect(coordinator.businessLogicInvocations == 1)
        #expect(coordinator.viewDelegate == nil)
    }

    @Test("After delegate deallocation, further calls do not deliver")
    func callsAfterDeallocationAreNoOp() {
        let coordinator = MockCoordinator()

        autoreleasepool {
            let delegate = MockViewDelegate()
            coordinator.initialize(with: delegate)
            coordinator.performBusinessLogic()
            #expect(delegate.navigationCount == 1)
        }

        // Delegate is gone; further calls should not crash and should not deliver.
        coordinator.performBusinessLogic()
        #expect(coordinator.businessLogicInvocations == 2)
        #expect(coordinator.viewDelegate == nil)
    }
}
