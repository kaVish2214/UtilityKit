//
//  CoordinatedViewController.swift
//  UtilityKit
//
//  Copyright (c) 2026 kaVi Gevariya (@kaVish2214)
//
//  This Source Code Form is subject to the terms of the Mozilla Public License,
//  v. 2.0. If a copy of the MPL was not distributed with this file, You can
//  obtain one at https://mozilla.org/MPL/2.0/.
//  SPDX-License-Identifier: MPL-2.0
//

#if canImport(UIKit)

import UIKit

/// A `UIViewController` that is driven by a coordinator.
///
/// `CoordinatedViewController` is the UIKit counterpart to ``CoordinatedView``.
/// It refines `UIViewController` with the requirement that the conformer holds a
/// reference to its coordinator, giving the screen a single, well-defined channel
/// for business logic.
///
/// ## Roles in This Architecture
/// ```
///   ┌────────────────────────────────┐
///   │   CoordinatedViewController    │
///   │   (UIKit screen, also acts as  │
///   │    the coordinator's           │
///   │    ViewDelegate — performs     │
///   │    push/present/dismiss here)  │
///   └───────────────┬────────────────┘
///                   │ user input → method call
///                   ▼
///   ┌────────────────────────────────┐
///   │     CoordinatorProtocol        │
///   │  (business logic, state, I/O)  │
///   └───────────────┬────────────────┘
///                   │ viewDelegate?.navigate / present / dismiss
///                   ▼
///                back to the VC above
/// ```
///
/// The view controller plays two roles at once:
/// 1. It **owns** a coordinator (via ``coordinator``) and calls into it for
///    business logic — "user tapped login", "view appeared", etc.
/// 2. It **implements** the coordinator's `ViewDelegate` so that when the coordinator
///    needs UIKit-side work done (push, present, dismiss, alert), it calls back into
///    the very same view controller.
///
/// This self-as-delegate pattern is what makes the architecture click in UIKit:
/// the VC is the natural place for both incoming user input and outgoing
/// UIKit navigation, because UIKit navigation requires a `UIViewController` reference
/// to begin with.
///
/// ## Example
/// ```swift
/// final class LoginViewController: UIViewController, CoordinatedViewController, LoginViewDelegate {
///
///     // 1. Holds the coordinator (this protocol's requirement).
///     let coordinator: any LoginCoordinating
///
///     init(coordinator: any LoginCoordinating) {
///         self.coordinator = coordinator
///         super.init(nibName: nil, bundle: nil)
///     }
///     required init?(coder: NSCoder) { fatalError() }
///
///     override func viewDidLoad() {
///         super.viewDidLoad()
///         // 2. Hand ourselves to the coordinator as its ViewDelegate.
///         coordinator.initialize(with: self)
///     }
///
///     // 3. User input → straight to the coordinator (business logic).
///     @objc private func signInTapped() {
///         coordinator.login(email: emailField.text ?? "", password: passwordField.text ?? "")
///     }
///
///     // 4. The coordinator's ViewDelegate methods are implemented here,
///     //    performing the actual UIKit navigation/presentation.
///     func navigateToHome() {
///         navigationController?.pushViewController(HomeViewController(), animated: true)
///     }
///     func showError(_ message: String) {
///         present(UIAlertController.error(message), animated: true)
///     }
/// }
/// ```
///
/// ## SwiftUI Bridging
/// When you host a ``CoordinatedView`` inside a `UIHostingController`, the parent
/// `UIViewController` that owns the hosting controller is the natural place to adopt
/// `CoordinatedViewController`. It holds the coordinator, hands itself to the
/// coordinator as the `ViewDelegate`, and performs UIKit navigation when the
/// coordinator requests it — even though the visible UI is pure SwiftUI.
///
/// ## Design Note — Why `Coordinator` is Not Constrained to `CoordinatorProtocol`
/// The ``Coordinator`` associated type is intentionally **unconstrained**. The reason
/// is identical to ``CoordinatedView``: ``CoordinatorProtocol`` is a PAT (protocol
/// with associated types), so constraining `Coordinator: CoordinatorProtocol` forces
/// callers to deal with its associated-type machinery at the view-controller boundary.
///
/// Leaving it open lets the VC hold:
/// - A full ``CoordinatorProtocol`` conformer.
/// - A refined sub-protocol existential like `any LoginCoordinating` *(recommended)*.
/// - A lightweight stand-in for tests or storyboard previews.
///
/// **In practice**, the held value should always be a ``CoordinatorProtocol``
/// conformer (or an existential of a sub-protocol that refines it).
///
/// ### Recommended Pattern
/// Define a sub-protocol of `CoordinatorProtocol` that pins down the `ViewDelegate`
/// associated type, then have the view controller hold it as an existential:
/// ```swift
/// protocol LoginCoordinating: CoordinatorProtocol where ViewDelegate == LoginViewDelegate {
///     func login(email: String, password: String)
/// }
///
/// final class LoginViewController: UIViewController, CoordinatedViewController {
///     let coordinator: any LoginCoordinating
///     // ...
/// }
/// ```
///
/// ## Comparison with `CoordinatedView`
/// - **`CoordinatedView`** requires `init(coordinator:)` because SwiftUI views are
///   value types created at render time.
/// - **`CoordinatedViewController`** does not require an initializer — UIKit
///   view controllers have many storyboard, nib, and programmatic init conventions,
///   so the protocol stays out of that decision and lets conformers choose.
public protocol CoordinatedViewController: UIViewController {

    /// The coordinator type that drives this view controller.
    ///
    /// Constrained only to `Sendable` so coordinators can safely cross isolation
    /// boundaries (e.g., when the coordinator dispatches async work off the main
    /// actor). It is deliberately **not** constrained to ``CoordinatorProtocol`` —
    /// see the design note on ``CoordinatedViewController`` for why.
    ///
    /// In practice, this should be a ``CoordinatorProtocol`` conformer (or an
    /// existential of a sub-protocol that refines it), both of which already
    /// satisfy `Sendable`.
    associatedtype Coordinator: Sendable

    /// The coordinator that owns this screen's business logic and routes UIKit-side
    /// actions back to the view controller via its `viewDelegate`.
    var coordinator: Coordinator { get }
}

#endif
