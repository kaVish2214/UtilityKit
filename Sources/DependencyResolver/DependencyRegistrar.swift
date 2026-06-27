//
//  DependencyRegistrar.swift
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

// MARK: - DependencyRegistrar

/// A protocol for types responsible for batch-registering dependencies into
/// the Factory container.
///
/// Use `DependencyRegistrar` to group related registrations into a single
/// entry point that can be called at launch or when a feature module loads:
///
/// ```swift
/// enum NetworkModule: DependencyRegistrar {
///     static func registerDependencies(_ resolver: Resolver) {
///         // Register factories on the resolver / Container here.
///     }
/// }
///
/// // At app launch:
/// NetworkModule.registerDependencies(Container.shared)
/// ```
public protocol DependencyRegistrar {

    /// A façade alias for Factory's `Resolving` protocol.
    typealias Resolver = Resolving

    /// Registers all dependencies this module provides.
    ///
    /// - Parameter resolver: The resolver (typically `Container.shared`) to
    ///   register factories against.
    static func registerDependencies(_ resolver: Resolver)
}
