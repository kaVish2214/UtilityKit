//
//  DependencyRegistrar.swift
//  DependencyResolver
//
//  Created by kavi gevariya on 21/02/25.
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
