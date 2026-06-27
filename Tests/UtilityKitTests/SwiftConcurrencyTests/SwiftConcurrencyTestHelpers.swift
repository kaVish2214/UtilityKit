// Copyright (c) 2026 kaVi Gevariya (@kaVish2214)
//
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file, You can
// obtain one at https://mozilla.org/MPL/2.0/.
// SPDX-License-Identifier: MPL-2.0

import Foundation
@testable import SwiftConcurrency

/// A non-Sendable reference type used to verify that `withLockUnchecked` can mutate
/// values that don't conform to `Sendable`.
final class NonSendableBox {
    var value: Int
    init(_ value: Int) { self.value = value }
}
