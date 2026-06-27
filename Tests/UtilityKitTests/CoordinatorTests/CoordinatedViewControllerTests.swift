// Copyright (c) 2026 kaVi Gevariya (@kaVish2214)
//
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file, You can
// obtain one at https://mozilla.org/MPL/2.0/.
// SPDX-License-Identifier: MPL-2.0

#if canImport(UIKit)

import Testing
import Foundation
import UIKit
@testable import Coordinator

// MARK: - Test View Controller

@MainActor
final class TestCoordinatedVC: UIViewController, CoordinatedViewController, TestViewDelegate {
    let coordinator: any TestCoordinating
    let counter = NavigationCounter()

    init(coordinator: any TestCoordinating) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    nonisolated func didReceiveNavigation() {
        counter.increment()
    }
}

// MARK: - Tests

@MainActor
@Suite("CoordinatedViewController")
struct CoordinatedViewControllerTests {

    @Test("VC stores the coordinator passed in init")
    func vcStoresCoordinator() {
        let coordinator = MockCoordinator()
        let vc = TestCoordinatedVC(coordinator: coordinator)

        #expect(vc.coordinator as AnyObject === coordinator)
    }

    @Test("Self-as-delegate pattern: VC can be passed to coordinator.initialize")
    func selfAsDelegatePattern() {
        let coordinator = MockCoordinator()
        let vc = TestCoordinatedVC(coordinator: coordinator)

        coordinator.initialize(with: vc)

        #expect(coordinator.viewDelegate === vc)
    }

    @Test("After self-as-delegate wiring, business logic routes back to the VC")
    func roundTripThroughVC() {
        let coordinator = MockCoordinator()
        let vc = TestCoordinatedVC(coordinator: coordinator)
        coordinator.initialize(with: vc)

        coordinator.performBusinessLogic()
        coordinator.performBusinessLogic()

        #expect(coordinator.businessLogicInvocations == 2)
        #expect(vc.counter.count == 2)
    }

    @Test("Multiple VCs maintain independent navigation counts")
    func multipleVCsAreIndependent() {
        let coordinatorA = MockCoordinator()
        let coordinatorB = MockCoordinator()
        let vcA = TestCoordinatedVC(coordinator: coordinatorA)
        let vcB = TestCoordinatedVC(coordinator: coordinatorB)

        coordinatorA.initialize(with: vcA)
        coordinatorB.initialize(with: vcB)

        coordinatorA.performBusinessLogic()
        coordinatorA.performBusinessLogic()
        coordinatorB.performBusinessLogic()

        #expect(vcA.counter.count == 2)
        #expect(vcB.counter.count == 1)
    }

    @Test("VC's coordinator reference is the same one used externally")
    func coordinatorIdentityIsPreserved() {
        let coordinator = MockCoordinator()
        let vc = TestCoordinatedVC(coordinator: coordinator)

        #expect(vc.coordinator as AnyObject === coordinator)
        coordinator.performBusinessLogic()
        #expect((vc.coordinator as AnyObject as? MockCoordinator)?.businessLogicInvocations == 1)
    }
}

#endif
