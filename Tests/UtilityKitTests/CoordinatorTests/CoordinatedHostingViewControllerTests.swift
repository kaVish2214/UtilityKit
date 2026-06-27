// Copyright (c) 2026 kaVi Gevariya (@kaVish2214)
//
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file, You can
// obtain one at https://mozilla.org/MPL/2.0/.
// SPDX-License-Identifier: MPL-2.0

#if canImport(UIKit)

import Testing
import Foundation
import SwiftUI
import UIKit
@testable import Coordinator

// MARK: - Concrete-typed coordinated view (avoids existential at the view level)

struct ConcreteCoordinatedView: CoordinatedView {
    let coordinator: MockCoordinator

    var body: some View {
        Text("Concrete")
    }
}

// MARK: - Test Sub-protocol
//
// Refines CoordinatedHostingViewController with the constraint that
// Coordinator conforms to TestCoordinating. The conforming hosting controller
// can then bind a concrete-typed coordinator (MockCoordinator), avoiding the
// existential-in-UIHostingController-subclass pattern that currently trips a
// Swift compiler SILGen crash.
protocol TestCoordinatedHosting: CoordinatedHostingViewController
    where Coordinator: TestCoordinating
{
}

// MARK: - Test Hosting Controller

@MainActor
final class TestConcreteHostingController:
    UIHostingController<ConcreteCoordinatedView>,
    TestCoordinatedHosting
{
    typealias Coordinator = MockCoordinator
    typealias RootCoordinatedView = ConcreteCoordinatedView

    required init(coordinator: MockCoordinator?) {
        guard let coordinator else { fatalError("coordinator required") }
        super.init(rootView: ConcreteCoordinatedView(coordinator: coordinator))
    }
    @MainActor required dynamic init?(coder: NSCoder) { fatalError() }
}

// MARK: - Tests

@MainActor
@Suite("CoordinatedHostingViewController")
struct CoordinatedHostingViewControllerTests {

    @Test("Hosting controller can be created with a coordinator")
    func canBeCreatedWithCoordinator() {
        let coordinator = MockCoordinator()
        let host = TestConcreteHostingController(coordinator: coordinator)

        #expect(host.rootView.coordinator === coordinator)
    }

    @Test("Root view's coordinator is the same instance the host was created with")
    func coordinatorSharedBetweenHostAndRoot() {
        let coordinator = MockCoordinator()
        let host = TestConcreteHostingController(coordinator: coordinator)

        #expect(host.rootView.coordinator === coordinator)
    }

    @Test("Coordinator wired with an external delegate can drive it through the hosted view")
    func coordinatorWithExternalDelegate() {
        let coordinator = MockCoordinator()
        let delegate = MockViewDelegate()
        coordinator.initialize(with: delegate)

        let host = TestConcreteHostingController(coordinator: coordinator)

        host.rootView.coordinator.performBusinessLogic()
        host.rootView.coordinator.performBusinessLogic()

        #expect(coordinator.businessLogicInvocations == 2)
        #expect(delegate.navigationCount == 2)
    }

    @Test("Multiple hosting controllers stay independent")
    func multipleHostsAreIndependent() {
        let coordinatorA = MockCoordinator()
        let coordinatorB = MockCoordinator()
        let hostA = TestConcreteHostingController(coordinator: coordinatorA)
        let hostB = TestConcreteHostingController(coordinator: coordinatorB)

        #expect(hostA.rootView.coordinator === coordinatorA)
        #expect(hostB.rootView.coordinator === coordinatorB)
        #expect(hostA.rootView.coordinator !== hostB.rootView.coordinator)
    }
}

#endif
