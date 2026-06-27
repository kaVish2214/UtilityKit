// Copyright (c) 2026 kaVi Gevariya (@kaVish2214)
//
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file, You can
// obtain one at https://mozilla.org/MPL/2.0/.
// SPDX-License-Identifier: MPL-2.0

import Foundation
import SwiftUI
@testable import Coordinator

// MARK: - Test Protocols

protocol TestViewDelegate: AnyObject, Sendable {
    func didReceiveNavigation()
}

protocol TestCoordinating: CoordinatorProtocol where ViewDelegate == TestViewDelegate {
    var businessLogicInvocations: Int { get }
    func performBusinessLogic()
}

// MARK: - Mock Coordinator

final class MockCoordinator: TestCoordinating, @unchecked Sendable {
    typealias ViewDelegate = TestViewDelegate

    private let lock = NSLock()
    private weak var _viewDelegate: TestViewDelegate?
    private var _businessLogicInvocations = 0

    var viewDelegate: TestViewDelegate? {
        lock.lock(); defer { lock.unlock() }
        return _viewDelegate
    }

    var businessLogicInvocations: Int {
        lock.lock(); defer { lock.unlock() }
        return _businessLogicInvocations
    }

    func initialize(with viewDelegate: TestViewDelegate) {
        lock.lock()
        _viewDelegate = viewDelegate
        lock.unlock()
    }

    func performBusinessLogic() {
        lock.lock()
        _businessLogicInvocations += 1
        let delegate = _viewDelegate
        lock.unlock()
        delegate?.didReceiveNavigation()
    }
}

// MARK: - Mock View Delegate (non-VC)

final class MockViewDelegate: TestViewDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private var _navigationCount = 0

    var navigationCount: Int {
        lock.lock(); defer { lock.unlock() }
        return _navigationCount
    }

    func didReceiveNavigation() {
        lock.lock()
        _navigationCount += 1
        lock.unlock()
    }
}

// MARK: - Thread-safe Counter (for VC-bound delegates)

final class NavigationCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var _count = 0

    var count: Int {
        lock.lock(); defer { lock.unlock() }
        return _count
    }

    func increment() {
        lock.lock()
        _count += 1
        lock.unlock()
    }
}

// MARK: - Mock CoordinatedView

struct MockCoordinatedView: CoordinatedView {
    let coordinator: any TestCoordinating

    var body: some View {
        Text("Mock")
    }
}
