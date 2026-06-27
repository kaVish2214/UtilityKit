// Copyright (c) 2026 kaVi Gevariya (@kaVish2214)
//
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file, You can
// obtain one at https://mozilla.org/MPL/2.0/.
// SPDX-License-Identifier: MPL-2.0

import Foundation
@testable import MultiCastDelegate

final class MockDelegate: MultiCastDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private var _receivedValues: [Int] = []

    var receivedValues: [Int] {
        lock.lock()
        defer { lock.unlock() }
        return _receivedValues
    }

    func didReceiveValue(_ value: Int) {
        lock.lock()
        defer { lock.unlock() }
        _receivedValues.append(value)
    }
}

final class TestMultiCaster: DelegateMultiCasting, @unchecked Sendable {
    typealias Delegate = MockDelegate
    let delegates: any DelegateSubscription = DelegateSubscriptionHandle()
}

extension DispatchQueue {
    func drainAsync() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.async(flags: .barrier) {
                continuation.resume()
            }
        }
    }
}
