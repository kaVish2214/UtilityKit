//
//  CoordinatorProtocol.swift
//  UtilityKit
//
//  Created by kavi gevariya on 20/05/26.
//

import Foundation


/// A protocol that owns the business logic for a screen and orchestrates UIKit-side
/// navigation/presentation through a delegate.
///
/// A `CoordinatorProtocol` conformer is the **brain** of a screen — it holds state,
/// performs networking, persistence, and domain decisions, and decides when the
/// screen needs to navigate, present, dismiss, or show alerts. Because SwiftUI views
/// hosted via `UIHostingController` can't directly trigger UIKit navigation, the
/// coordinator delegates those UIKit-side actions through a ``ViewDelegate``, which
/// the UIKit hosting layer (typically the parent `UIViewController`) implements.
///
/// ## Data Flow
/// ```
///   ┌─────────────────┐   user input    ┌────────────────────┐
///   │  SwiftUI View   │ ──────────────▶ │    Coordinator     │
///   │ (CoordinatedView)│                 │ (business logic +  │
///   │                 │ ◀────────────── │   state + I/O)     │
///   └─────────────────┘   state/output  └─────────┬──────────┘
///                                                 │
///                                  navigate/present/dismiss
///                                                 ▼
///                                       ┌────────────────────┐
///                                       │   ViewDelegate     │
///                                       │ (implemented by    │
///                                       │  UIKit host VC)    │
///                                       └────────────────────┘
/// ```
///
/// 1. The SwiftUI view (or UIKit view controller) calls methods on the coordinator
///    when the user does something — `coordinator.loginTapped(...)`.
/// 2. The coordinator runs business logic — validation, API calls, state updates.
/// 3. When the coordinator (or the view itself) needs **UIKit-side work**, it calls
///    methods on ``viewDelegate``: `viewDelegate?.navigateToHome()`,
///    `viewDelegate?.presentAlert(...)`, `viewDelegate?.dismiss()`.
/// 4. The UIKit hosting layer (the `UIViewController` that owns the
///    `UIHostingController`) conforms to `ViewDelegate` and performs the actual
///    `push`, `present`, `dismiss`, etc.
///
/// ## Example
/// ```swift
/// // 1. Define the UIKit-side actions the screen can request.
/// protocol LoginViewDelegate: AnyObject {
///     func navigateToHome()
///     func presentForgotPassword()
///     func showError(_ message: String)
/// }
///
/// // 2. The coordinator holds business logic and triggers UIKit-side actions.
/// final class LoginCoordinator: CoordinatorProtocol {
///     typealias ViewDelegate = LoginViewDelegate
///     weak var viewDelegate: LoginViewDelegate?
///
///     func initialize(with viewDelegate: LoginViewDelegate) {
///         self.viewDelegate = viewDelegate
///     }
///
///     // Called by the SwiftUI view on user input.
///     func login(email: String, password: String) {
///         Task {
///             do {
///                 try await authService.signIn(email, password)
///                 await viewDelegate?.navigateToHome()   // UIKit work
///             } catch {
///                 await viewDelegate?.showError(error.localizedDescription)
///             }
///         }
///     }
/// }
///
/// // 3. The hosting UIViewController implements the UIKit-side actions.
/// final class LoginHostController: UIViewController, LoginViewDelegate {
///     func navigateToHome() { navigationController?.pushViewController(HomeVC(), animated: true) }
///     func presentForgotPassword() { present(ForgotPasswordVC(), animated: true) }
///     func showError(_ message: String) { /* present UIAlertController */ }
/// }
/// ```
///
/// ## Design Note — Role of `ViewDelegate`
/// `ViewDelegate` is the **outbound channel from the Coordinator to UIKit**. It exists
/// because SwiftUI views, when embedded in `UIHostingController`, can't perform UIKit
/// navigation themselves — they need to hand that work to the surrounding
/// `UIViewController`.
///
/// **Do** put on `ViewDelegate`:
/// - UIKit navigation: `push`, `pop`, `present`, `dismiss`.
/// - System UI presentations: alerts, action sheets, share sheets, picker controllers.
/// - Anything that requires a `UIViewController` reference to execute.
///
/// **Do not** put on `ViewDelegate`:
/// - Business logic, networking, persistence, or domain decisions — those live on
///   the **Coordinator**.
/// - User input events (taps, text changes, gestures) — the SwiftUI/UIKit view sends
///   those directly to the **Coordinator**, not through `ViewDelegate`.
/// - State or data the view needs to render — that comes from the Coordinator
///   (via published properties, bindings, etc.), not from `ViewDelegate`.
///
/// **Who calls `ViewDelegate`?** Usually the Coordinator (after some business logic
/// decides the screen needs to navigate). The ``CoordinatedView`` itself may also
/// call `coordinator.viewDelegate?...` directly when an interaction maps 1:1 to a
/// UIKit-side action that needs no business decision.
///
/// **Who implements `ViewDelegate`?** The UIKit hosting layer — typically the
/// `UIViewController` that wraps the `UIHostingController`.
public protocol CoordinatorProtocol: AnyObject, Sendable {

    /// The UIKit-side action surface this coordinator can request.
    ///
    /// See the "Role of `ViewDelegate`" design note on ``CoordinatorProtocol`` for
    /// what should — and should not — live on this type.
    associatedtype ViewDelegate: Sendable

    /// The UIKit-side delegate that performs navigation/presentation on behalf of
    /// this coordinator, if currently bound.
    ///
    /// Conforming types are expected to hold this **weakly** — the UIKit hosting
    /// `UIViewController` typically owns the coordinator (directly or transitively),
    /// so a strong reference here would create a retain cycle.
    var viewDelegate: ViewDelegate? { get }

    /// Binds the UIKit-side `ViewDelegate` to this coordinator and kicks off any
    /// initial work (fetching data, wiring up child coordinators, etc.).
    ///
    /// - Parameter viewDelegate: The UIKit-side recipient of navigation/presentation
    ///   calls. The coordinator should store this weakly.
    func initialize(with viewDelegate: ViewDelegate)
}

