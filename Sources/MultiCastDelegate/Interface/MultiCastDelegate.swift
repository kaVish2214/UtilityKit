//
//  MultiCastDelegate.swift
//  UtilityKit
//
//  Created by kavi gevariya on 26/04/26.
//

import Foundation

/// The base protocol for any type that can receive multicast delegate callbacks.
///
/// Conforming types must be class-based (`NSObjectProtocol`) to support:
/// - **Weak reference storage** — subscribers are stored in `NSHashTable.weakObjects()`
///   and are automatically cleaned up when deallocated.
/// - **Identity-based equality** — `NSObjectProtocol` provides `isEqual(_:)` and `hash`,
///   which ``DelegateSubscriptionHandle`` relies on for subscription management.
///
/// Create a domain-specific delegate protocol by extending `MultiCastDelegate`:
/// ```swift
/// protocol DownloadDelegate: MultiCastDelegate {
///     func downloadDidStart(_ url: URL)
///     func downloadDidFinish(_ url: URL, data: Data)
/// }
/// ```
///
/// Then use it as the `Delegate` associated type of a ``DelegateMultiCasting`` conformance.
public protocol MultiCastDelegate: NSObjectProtocol, Sendable {

}
