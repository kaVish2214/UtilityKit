// Copyright (c) 2026 kaVi Gevariya (@kaVish2214)
//
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file, You can
// obtain one at https://mozilla.org/MPL/2.0/.
// SPDX-License-Identifier: MPL-2.0

import Testing
import Foundation
import SwiftUI
@testable import Coordinator

@Suite("CoordinatedView")
struct CoordinatedViewTests {

    @Test("View can be created with a coordinator")
    func viewCreation() {
        let coordinator = MockCoordinator()
        let view = MockCoordinatedView(coordinator: coordinator)

        #expect(view.coordinator as AnyObject === coordinator)
    }

    @Test("Two views can share the same coordinator instance")
    func sharedCoordinator() {
        let coordinator = MockCoordinator()
        let viewA = MockCoordinatedView(coordinator: coordinator)
        let viewB = MockCoordinatedView(coordinator: coordinator)

        #expect(viewA.coordinator as AnyObject === viewB.coordinator as AnyObject)
    }

    @Test("Copied view shares the coordinator (class semantics through struct)")
    func copyPreservesCoordinatorReference() {
        let coordinator = MockCoordinator()
        let original = MockCoordinatedView(coordinator: coordinator)
        let copy = original

        #expect(original.coordinator as AnyObject === copy.coordinator as AnyObject)
    }

    @Test("Different views can have different coordinators")
    func differentCoordinators() {
        let coordinatorA = MockCoordinator()
        let coordinatorB = MockCoordinator()
        let viewA = MockCoordinatedView(coordinator: coordinatorA)
        let viewB = MockCoordinatedView(coordinator: coordinatorB)

        #expect(viewA.coordinator as AnyObject !== viewB.coordinator as AnyObject)
    }

    @Test("View's coordinator can be used to invoke business logic")
    func viewDrivesCoordinator() {
        let coordinator = MockCoordinator()
        let delegate = MockViewDelegate()
        coordinator.initialize(with: delegate)

        let view = MockCoordinatedView(coordinator: coordinator)
        view.coordinator.performBusinessLogic()

        #expect(coordinator.businessLogicInvocations == 1)
        #expect(delegate.navigationCount == 1)
    }
}
