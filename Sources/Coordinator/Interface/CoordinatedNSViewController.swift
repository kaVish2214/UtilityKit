//
//  CoordinatedNSViewController.swift
//  UtilityKit
//
//  Copyright (c) 2026 kaVi Gevariya (@kaVish2214)
//
//  This Source Code Form is subject to the terms of the Mozilla Public License,
//  v. 2.0. If a copy of the MPL was not distributed with this file, You can
//  obtain one at https://mozilla.org/MPL/2.0/.
//  SPDX-License-Identifier: MPL-2.0
//

#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

/// An `NSViewController` that is driven by a coordinator.
///
/// `CoordinatedNSViewController` is the AppKit counterpart to
/// ``CoordinatedViewController``. It refines `NSViewController` with the requirement
/// that the conformer holds a reference to its coordinator, giving the screen a
/// single, well-defined channel for business logic.
///
/// ## Roles in This Architecture
/// ```
///   ┌───────────────────────────────────┐
///   │   CoordinatedNSViewController     │
///   │   (AppKit screen, also acts as    │
///   │    the coordinator's ViewDelegate │
///   │    — performs presentAsSheet /    │
///   │    presentAsModalWindow / dismiss │
///   │    here)                          │
///   └─────────────────┬─────────────────┘
///                     │ user input → method call
///                     ▼
///   ┌───────────────────────────────────┐
///   │       CoordinatorProtocol         │
///   │   (business logic, state, I/O)    │
///   └─────────────────┬─────────────────┘
///                     │ viewDelegate?.present / dismiss / ...
///                     ▼
///                back to the VC above
/// ```
///
/// The view controller plays two roles at once:
/// 1. It **owns** a coordinator (via ``coordinator``) and calls into it for
///    business logic — "user clicked Sign In", "view did load", etc.
/// 2. It **implements** the coordinator's `ViewDelegate` so that when the coordinator
///    needs AppKit-side work done (present a sheet, push to a navigation controller,
///    dismiss, show an alert), it calls back into the very same view controller.
///
/// This self-as-delegate pattern is what makes the architecture click in AppKit:
/// the VC is the natural place for both incoming user input and outgoing AppKit
/// navigation, because AppKit presentation typically requires an `NSViewController`
/// reference to begin with.
///
/// ## Example
/// ```swift
/// final class PreferencesViewController: NSViewController, CoordinatedNSViewController, PreferencesViewDelegate {
///
///     let coordinator: any PreferencesCoordinating
///
///     init(coordinator: any PreferencesCoordinating) {
///         self.coordinator = coordinator
///         super.init(nibName: nil, bundle: nil)
///     }
///     required init?(coder: NSCoder) { fatalError() }
///
///     override func viewDidLoad() {
///         super.viewDidLoad()
///         coordinator.initialize(with: self)
///     }
///
///     // ViewDelegate methods — perform real AppKit presentation here.
///     func showAdvancedOptions() {
///         presentAsSheet(AdvancedOptionsViewController(coordinator: ...))
///     }
///     func showError(_ message: String) {
///         let alert = NSAlert(); alert.messageText = message
///         alert.runModal()
///     }
/// }
/// ```
///
/// ## Design Note — Why `Coordinator` Is Not Constrained to `CoordinatorProtocol`
/// The ``Coordinator`` associated type is intentionally **unconstrained beyond
/// `Sendable`**. The reason is identical to ``CoordinatedViewController``:
/// ``CoordinatorProtocol`` is a PAT (protocol with associated types), so
/// constraining `Coordinator: CoordinatorProtocol` forces callers to deal with its
/// associated-type machinery at the view-controller boundary.
///
/// Leaving it open lets the VC hold:
/// - A full ``CoordinatorProtocol`` conformer.
/// - A refined sub-protocol existential like `any PreferencesCoordinating` *(recommended)*.
/// - A lightweight stand-in for tests or previews.
///
/// **In practice**, the held value should always be a ``CoordinatorProtocol``
/// conformer (or an existential of a sub-protocol that refines it), both of which
/// already satisfy `Sendable`.
///
/// ## Comparison with `CoordinatedViewController`
/// - **`CoordinatedViewController`** refines `UIViewController` and is available
///   wherever UIKit is (iOS, iPadOS, and Mac Catalyst).
/// - **`CoordinatedNSViewController`** refines `NSViewController` and is native
///   macOS-only (excluded from Mac Catalyst, which uses the UIKit variant).
/// - Both share the same role and design notes; pick the one matching the platform
///   you are building for.
public protocol CoordinatedNSViewController: NSViewController {

    /// The coordinator type that drives this view controller.
    ///
    /// Constrained only to `Sendable` so coordinators can safely cross isolation
    /// boundaries (e.g., when the coordinator dispatches async work off the main
    /// actor). It is deliberately **not** constrained to ``CoordinatorProtocol`` —
    /// see the design note on ``CoordinatedNSViewController`` for why.
    ///
    /// In practice, this should be a ``CoordinatorProtocol`` conformer (or an
    /// existential of a sub-protocol that refines it), both of which already
    /// satisfy `Sendable`.
    associatedtype Coordinator: Sendable

    /// The coordinator that owns this screen's business logic and routes AppKit-side
    /// actions back to the view controller via its `viewDelegate`.
    var coordinator: Coordinator { get }
}

#endif
