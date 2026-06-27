//
//  Factory+Resolve.swift
//  DependencyResolver
//
//  Copyright (c) 2026 kaVi Gevariya (@kaVish2214)
//
//  This Source Code Form is subject to the terms of the Mozilla Public License,
//  v. 2.0. If a copy of the MPL was not distributed with this file, You can
//  obtain one at https://mozilla.org/MPL/2.0/.
//  SPDX-License-Identifier: MPL-2.0
//

import Foundation
import Factory



/// Adds `Resolving` conformance to Factory's `Container`.
///
/// `Container` already satisfies `ManagedContainer` (a requirement of `Resolving`),
/// and the default implementations on `Resolving` supply `register(_:factory:)`,
/// `factory(_:)`, and `resolve(_:)`. This declaration simply opts `Container` in,
/// enabling its use anywhere a ``DependencyResolver/Resolver`` is expected.
extension Container: @retroactive Resolving { }
