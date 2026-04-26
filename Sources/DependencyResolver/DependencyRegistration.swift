//
//  DependencyRegistration.swift
//  UtilityKit
//
//  Created by kavi gevariya on 12/09/25.
//

import Foundation
import Factory

// MARK: - Public Type Aliases

/// A façade alias for Factory's `FactoryModifying`, which provides scope modifiers
/// (`.cached`, `.singleton`, etc.) on factory registrations.
public typealias ParameterRegistry = FactoryModifying

/// A façade alias for Factory's `ParameterFactory`, a factory that accepts
/// runtime parameters when resolving a dependency.
public typealias ParameterRegistration = ParameterFactory

// MARK: - DependencyRegistration

/// A protocol for defining parameterized dependency registrations.
///
/// Use `DependencyRegistration` when a dependency requires runtime parameters
/// to be resolved — for example, a detail screen that needs an item ID:
///
/// ```swift
/// struct DetailRegistration: DependencyRegistration {
///     typealias Parameter = String
///     typealias Registration = ParameterFactory<String, DetailViewModel>
///
///     func registration(for resolver: Resolver) -> Registration {
///         // Return the ParameterFactory configured on the container.
///     }
///
///     func resolve(parameter: String, resolver: Resolver) -> DetailViewModel? {
///         registration(for: resolver).resolve(parameter)
///     }
/// }
/// ```
public protocol DependencyRegistration: Sendable {

    /// The runtime parameter type required to resolve this dependency.
    associatedtype Parameter

    /// A façade alias for Factory's `Resolving` protocol.
    typealias Resolver = Resolving

    /// The parameterized factory type that produces the dependency.
    ///
    /// Must conform to ``ParameterRegistry`` (`FactoryModifying`) so that
    /// scope modifiers can be applied to the registration.
    associatedtype Registration: ParameterRegistry

    /// Returns the parameterized factory registration from the given resolver.
    ///
    /// - Parameter resolver: The resolver (typically `Container.shared`).
    /// - Returns: A ``ParameterRegistry``-conforming factory.
    func registration(for resolver: Resolver) -> Registration

    /// Resolves the dependency using the given parameter.
    ///
    /// - Parameters:
    ///   - parameter: The runtime value needed to create the dependency.
    ///   - resolver: The resolver to look up the registration in.
    /// - Returns: The resolved instance, or `nil` if resolution fails.
    func resolve(parameter: Parameter, resolver: Resolver) -> Registration.T?
}
