//
//  MultiCastDelegate.swift
//  UtilityKit
//
//  Copyright (c) 2026 kaVi Gevariya (@kaVish2214)
//
//  This Source Code Form is subject to the terms of the Mozilla Public License,
//  v. 2.0. If a copy of the MPL was not distributed with this file, You can
//  obtain one at https://mozilla.org/MPL/2.0/.
//  SPDX-License-Identifier: MPL-2.0
//

import Foundation

/// The base protocol for any type that can receive multicast delegate callbacks.
///
/// Conforming types must be class-based (`AnyObject`) so that subscribers can be:
/// - **Stored weakly** — ``DelegateSubscriptionHandle`` uses `NSHashTable.weakObjects()`,
///   which automatically removes subscribers when they are deallocated.
/// - **Identified by reference** — subscription management relies on object identity
///   to add and remove specific subscribers.
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
///
/// ## Design Note
/// `MultiCastDelegate` only requires `AnyObject` so that pure-Swift classes can adopt it
/// without any Objective-C runtime overhead. If your delegate protocol needs to expose
/// `@objc` methods, optional requirements, or interoperate with Objective-C, refine your
/// protocol to also require `NSObjectProtocol`:
/// ```swift
/// @objc protocol VideoPlayerDelegate: MultiCastDelegate, NSObjectProtocol {
///     @objc optional func playerDidPause()
/// }
/// ```
public protocol MultiCastDelegate: AnyObject, Sendable {

}
