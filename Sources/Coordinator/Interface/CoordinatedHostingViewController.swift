//
//  CoordinatedHostingViewController.swift
//  UtilityKit
//
//  Created by kavi gevariya on 20/05/26.
//

#if canImport(UIKit)

import SwiftUI

/// A `UIHostingController` that bridges a ``CoordinatedView`` into a UIKit navigation
/// stack, with the coordinator wiring enforced at the type level.
///
/// `CoordinatedHostingViewController` is the **glue protocol** that lets a SwiftUI
/// screen participate in a UIKit-driven navigation flow. It refines
/// `UIHostingController` with two compile-time guarantees:
///
/// 1. The hosted root view conforms to ``CoordinatedView``.
/// 2. The host's ``Coordinator`` matches the root view's ``CoordinatedView/Coordinator``.
///
/// Both guarantees come from the `where` clause on the protocol declaration, so any
/// mismatch (wrong root view, wrong coordinator type) is caught by the compiler
/// rather than as a runtime crash.
///
/// ## Where It Fits — The Four Protocols
/// ```
///   ┌────────────────────────────────────────────────────────────────┐
///   │                     CoordinatorProtocol                        │
///   │             (business logic, state, navigation calls)          │
///   └──────────────────────┬─────────────────────────────────────────┘
///                          │ drives
///         ┌────────────────┴──────────────────┐
///         ▼                                   ▼
///   ┌──────────────────┐              ┌────────────────────────────┐
///   │  CoordinatedView │              │  CoordinatedViewController │
///   │   (SwiftUI side) │              │       (pure UIKit)         │
///   └──────┬───────────┘              └────────────────────────────┘
///          │ wrapped by
///          ▼
///   ┌─────────────────────────────────────────────┐
///   │      CoordinatedHostingViewController       │
///   │ (UIHostingController bridge — this protocol)│
///   │  Hosts a CoordinatedView in a UIKit VC and  │
///   │  typically implements the coordinator's     │
///   │  ViewDelegate for navigation.               │
///   └─────────────────────────────────────────────┘
/// ```
///
/// In other words:
/// - Pure UIKit screens adopt ``CoordinatedViewController``.
/// - Pure SwiftUI views adopt ``CoordinatedView``.
/// - SwiftUI views that need to live inside a UIKit navigation stack are *hosted*
///   by a `CoordinatedHostingViewController`.
///
/// ## Example
/// ```swift
/// // 1. A coordinator sub-protocol that pins down the ViewDelegate.
/// protocol LoginCoordinating: CoordinatorProtocol where ViewDelegate == LoginViewDelegate {
///     func login(email: String, password: String)
/// }
///
/// // 2. The UIKit-side actions the screen can request.
/// protocol LoginViewDelegate: AnyObject {
///     func navigateToHome()
///     func showError(_ message: String)
/// }
///
/// // 3. The SwiftUI view.
/// struct LoginView: CoordinatedView {
///     let coordinator: any LoginCoordinating
///     var body: some View { /* ... */ }
/// }
///
/// // 4. The hosting controller — bridges LoginView into a UIKit nav stack
/// //    and acts as the coordinator's ViewDelegate.
/// final class LoginHostingController:
///     UIHostingController<LoginView>,
///     CoordinatedHostingViewController,
///     LoginViewDelegate
/// {
///     typealias Coordinator = any LoginCoordinating
///     typealias RootCoordinatedView = LoginView
///
///     let coordinator: (any LoginCoordinating)?
///
///     required init(coordinator: (any LoginCoordinating)?) {
///         self.coordinator = coordinator
///         super.init(rootView: LoginView(coordinator: coordinator!))
///         coordinator?.initialize(with: self)
///     }
///     @MainActor required dynamic init?(coder: NSCoder) { fatalError() }
///
///     // ViewDelegate methods — perform real UIKit navigation here.
///     func navigateToHome() {
///         navigationController?.pushViewController(HomeViewController(), animated: true)
///     }
///     func showError(_ message: String) {
///         present(UIAlertController.error(message), animated: true)
///     }
/// }
///
/// // 5. From the rest of UIKit, push it like any other VC:
/// let host = LoginHostingController(coordinator: LoginCoordinator())
/// navigationController.pushViewController(host, animated: true)
/// ```
///
/// ## Design Notes
///
/// ### Why the `where` Clause Exists
/// The two constraints in the `where` clause —
/// `Self: UIHostingController<Self.RootCoordinatedView>` and
/// `Self.RootCoordinatedView.Coordinator == Self.Coordinator` —
/// encode the relationship between the three moving parts (host, root view,
/// coordinator) directly in the type system:
///
/// - **`Self: UIHostingController<RootCoordinatedView>`** forces the conformer to
///   be a `UIHostingController` whose root view is the declared
///   ``RootCoordinatedView``. You cannot accidentally conform a plain
///   `UIViewController` or a `UIHostingController` over the wrong view type.
/// - **`RootCoordinatedView.Coordinator == Coordinator`** ensures the coordinator
///   stored on the host and the coordinator stored on the SwiftUI root view are
///   the **same type**, so they can share a single instance with no casting.
///
/// This is stricter than anything you could express on the conformer alone — by
/// hoisting it onto the protocol, every conformer is guaranteed to be wired
/// consistently, and mistakes surface as compile errors instead of runtime bugs.
///
/// ### Why `init(coordinator: Coordinator?)` Is Optional
/// The initializer accepts an optional coordinator to support real-world hosting
/// scenarios where the coordinator isn't always available at construction time:
///
/// - **Lazy injection** — the host is created before the coordinator is resolved
///   (e.g., the coordinator is fetched from a DI container in `viewDidLoad`).
/// - **Storyboards / nibs** — `UIHostingController` initializers fired by
///   `init(coder:)` can't pass a coordinator; conformers can store `nil` and inject
///   later.
/// - **Previews and tests** — a placeholder host without a coordinator is useful
///   when only the visual layout is being validated.
///
/// Conformers that always have a coordinator at init time can simply force-unwrap
/// inside their initializer; the optional is a flexibility lever, not a default.
///
/// ### Why `Coordinator` Is Not Constrained to `CoordinatorProtocol`
/// Same reasoning as ``CoordinatedView`` and ``CoordinatedViewController``:
/// constraining the associated type directly to ``CoordinatorProtocol`` would
/// force callers to deal with its PAT machinery at the hosting boundary. Leaving
/// it at `Sendable` lets the host hold a refined sub-protocol existential
/// (e.g., `any LoginCoordinating`), a stand-in for previews, or a full
/// `CoordinatorProtocol` conformer — all without ceremony.
public protocol CoordinatedHostingViewController
    where Self: UIHostingController<RootCoordinatedView>,
          RootCoordinatedView.Coordinator == Coordinator
{

    /// The SwiftUI view this controller hosts.
    ///
    /// Must conform to ``CoordinatedView`` so its coordinator wiring lines up with
    /// the host's. The protocol's `where` clause additionally requires
    /// `RootCoordinatedView.Coordinator == Coordinator`, guaranteeing that both
    /// sides reference the same coordinator type.
    associatedtype RootCoordinatedView: CoordinatedView

    /// The coordinator type shared by this hosting controller and its
    /// ``RootCoordinatedView``.
    ///
    /// Constrained to `Sendable` so the same instance can safely cross isolation
    /// boundaries between the SwiftUI view and any async work the coordinator
    /// performs. See the design note on ``CoordinatedHostingViewController`` for
    /// why this is not constrained to ``CoordinatorProtocol``.
    associatedtype Coordinator: Sendable

    /// Creates the hosting controller, optionally with a coordinator already bound.
    ///
    /// The coordinator is `Optional` to accommodate cases where the host is created
    /// before the coordinator is available (lazy DI, storyboard/coder init, previews).
    /// Conformers that always have a coordinator at construction time may treat the
    /// optional as required and force-unwrap.
    ///
    /// - Parameter coordinator: The coordinator to bind to both this host and its
    ///   ``RootCoordinatedView``. May be `nil` for deferred wiring.
    init(coordinator: Coordinator?)
}

#endif

