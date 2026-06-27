// Copyright (c) 2026 kaVi Gevariya (@kaVish2214)
//
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file, You can
// obtain one at https://mozilla.org/MPL/2.0/.
// SPDX-License-Identifier: MPL-2.0

import Testing
import Foundation
@testable import SwiftConcurrency

@Suite("ConcurrencyContainerProtocol")
struct ConcurrencyContainerProtocolTests {

    // MARK: - Existential Use

    @Test("Container can be held as an existential ConcurrencyContainerProtocol")
    func usableAsExistential() {
        let container: any ConcurrencyContainerProtocol<Int> = ConcurrencySafeContainer<Int>(1)

        container.withLockUnchecked { $0 += 41 }

        let value = container.withLockUnchecked { $0 }
        #expect(value == 42)
    }

    // MARK: - Generic Over Backend

    @Test("Generic functions can accept any ConcurrencyContainerProtocol")
    func genericOverBackend() {
        func bump<C: ConcurrencyContainerProtocol>(_ container: C) where C.State == Int {
            container.withLockUnchecked { $0 += 1 }
        }

        let container = ConcurrencySafeContainer<Int>(0)
        bump(container)
        bump(container)
        bump(container)

        #expect(container.withLock { $0 } == 3)
    }
}
