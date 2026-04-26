//
//  DependencyResolver.swift
//  DependencyResolver
//
//  Created by kavi gevariya on 18/12/24.
//

import Foundation
import Factory

// MARK: - DependencyResolver

/// A protocol that gives conforming types the ability to resolve dependencies
/// from the shared Factory `Container`.
///
/// Adopt `DependencyResolver` to gain a lightweight, type-safe entry point into
/// the dependency graph without coupling your code directly to `Container`:
///
/// ```swift
/// final class ProfileViewModel: DependencyResolver {
///     func load() {
///         let service: ProfileService? = resolved(ProfileService.self)
///         // or let the compiler infer the type:
///         let service: ProfileService? = resolved()
///     }
/// }
/// ```
///
/// Default implementations are provided for both requirements, backed by
/// `Container.shared`.
public protocol DependencyResolver {

    /// A façade alias for Factory's `Resolving` protocol.
    ///
    /// Using this alias lets conformers reference `Resolver` without importing
    /// Factory directly.
    typealias Resolver = Resolving

    /// Resolves a registered dependency of the given type.
    ///
    /// - Parameter type: The metatype to resolve. Defaults to `T.self` so the
    ///   type can be inferred from context.
    /// - Returns: The resolved instance, or `nil` if no registration exists.
    func resolved<T>(_ type: T.Type) -> T?

    /// The underlying resolver backing this instance.
    var resolver: any Resolver { get }
}

// MARK: - Default Implementations

extension DependencyResolver {

    /// Default: resolves via `Container.shared`.
    public func resolved<T>(_ type: T.Type = T.self) -> T? {
        return Container.shared.resolve()
    }

    /// Default: returns `Container.shared`.
    public var resolver: any Resolver {
        return Container.shared
    }
}
