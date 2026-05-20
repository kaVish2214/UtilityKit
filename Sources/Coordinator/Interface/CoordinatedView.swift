//
//  CoordinatedView.swift
//  UtilityKit
//
//  Created by kavi gevariya on 20/05/26.
//

import SwiftUI

/// A SwiftUI `View` that is driven by a coordinator.
///
/// `CoordinatedView` is the SwiftUI-side counterpart to ``CoordinatorProtocol``.
/// The view holds a reference to its coordinator and **calls methods directly on
/// the coordinator** for user input. The coordinator runs the business logic and,
/// when UIKit-side work is needed (navigation, presentation, alerts), invokes its
/// own `viewDelegate` — which is implemented by the surrounding `UIViewController`.
///
/// ## Where to Send Events
/// - **User input (taps, text changes, gestures)** → call methods on
///   ``coordinator`` directly. Example: `coordinator.login(email:password:)`.
/// - **UIKit-side actions the view itself can decide on** (e.g., a "Close" button
///   that just needs to dismiss the screen with no business logic) → call
///   `coordinator.viewDelegate?.dismiss()`. Most navigation should still flow
///   through the coordinator, but this shortcut is allowed.
/// - **Anything requiring business logic, networking, or state changes** → goes to
///   ``coordinator``, never to `viewDelegate`.
///
/// ## Example
/// ```swift
/// struct LoginView: CoordinatedView {
///     let coordinator: any LoginCoordinating
///     @State private var email = ""
///     @State private var password = ""
///
///     var body: some View {
///         VStack {
///             TextField("Email", text: $email)
///             SecureField("Password", text: $password)
///
///             // User input → straight to the coordinator (business logic).
///             Button("Sign In") {
///                 coordinator.login(email: email, password: password)
///             }
///
///             // Pure UIKit-side action → the view can hit viewDelegate directly.
///             Button("Close") {
///                 coordinator.viewDelegate?.dismiss()
///             }
///         }
///     }
/// }
/// ```
///
/// ## Design Note — Why `Coordinator` is Not Constrained to `CoordinatorProtocol`
/// The ``Coordinator`` associated type is intentionally **unconstrained** (only
/// `Sendable`). It is *not* declared as `Coordinator: CoordinatorProtocol`.
///
/// **Reason:** `CoordinatorProtocol` itself has an associated type (`ViewDelegate`),
/// which makes it a PAT (protocol with associated types). PATs cannot be used directly
/// as concrete types — only as constraints — and that creates friction at the view
/// boundary, where SwiftUI views typically want to hold an existential like
/// `any LoginCoordinating` (a refined sub-protocol) without forcing every conformer
/// to also resolve `CoordinatorProtocol`'s associated types.
///
/// By leaving ``Coordinator`` unconstrained:
/// - Views can hold **any kind of coordinator-shaped object** — a full
///   `CoordinatorProtocol` conformer, a refined protocol existential (recommended),
///   or even a lightweight value-type stand-in for previews and tests.
/// - The view layer stays decoupled from `CoordinatorProtocol`'s associated-type
///   machinery while still benefiting from the same architectural split.
///
/// **In practice**, callers should still pass a `CoordinatorProtocol` conformer
/// (or an existential of a sub-protocol that refines it). The constraint is omitted
/// for flexibility, not because non-coordinators are expected.
///
/// ### Recommended Pattern
/// Define a sub-protocol of `CoordinatorProtocol` that exposes only what the view
/// needs, then have the view hold it as an existential:
/// ```swift
/// protocol LoginCoordinating: CoordinatorProtocol where ViewDelegate == LoginViewDelegate {}
///
/// struct LoginView: CoordinatedView {
///     let coordinator: any LoginCoordinating
///     init(coordinator: any LoginCoordinating) { self.coordinator = coordinator }
///     var body: some View { ... }
/// }
/// ```
public protocol CoordinatedView: View {

    /// The coordinator type that drives this view.
    ///
    /// Unconstrained beyond `Sendable` — see the design note on ``CoordinatedView``
    /// for why this is intentional. In practice, this should be a
    /// ``CoordinatorProtocol`` conformer (or an existential of a sub-protocol
    /// that refines it).
    associatedtype Coordinator: Sendable

    /// The coordinator that drives this view's behavior and receives its events.
    var coordinator: Coordinator { get }

    /// Creates the view bound to the given coordinator.
    ///
    /// - Parameter coordinator: The coordinator that will receive view-side events
    ///   and drive navigation/state.
    init(coordinator: Coordinator)
}
