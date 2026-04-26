//
//  Factory+Resolve.swift
//  DependencyResolver
//
//  Created by kavi gevariya on 18/12/24.
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
