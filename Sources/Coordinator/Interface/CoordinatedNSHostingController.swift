//
//  CoordinatedNSHostingController.swift
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

import SwiftUI

/// An `NSHostingController` that bridges a ``CoordinatedView`` into an AppKit
/// window/navigation hierarchy, with the coordinator wiring enforced at the type level.
///
/// `CoordinatedNSHostingController` is the AppKit counterpart to
/// ``CoordinatedHostingViewController``. It refines `NSHostingController` with two
/// compile-time guarantees:
///
/// 1. The hosted root view conforms to ``CoordinatedView``.
/// 2. The host's ``Coordinator`` matches the root view's ``CoordinatedView/Coordinator``.
///
/// Both guarantees come from the `where` clause, so any mismatch (wrong root view,
/// wrong coordinator type) is caught by the compiler rather than as a runtime crash.
///
/// ## Where It Fits — The macOS Picture
/// ```
///   ┌────────────────────────────────────────────────────────────────┐
///   │                     CoordinatorProtocol                        │
///   │             (business logic, state, navigation calls)          │
///   └──────────────────────┬─────────────────────────────────────────┘
///                          │ drives
///         ┌────────────────┴──────────────────┐
///         ▼                                   ▼
///   ┌──────────────────┐                  ┌────────────────────────────┐
///   │  CoordinatedView │                  │ CoordinatedNSViewController│
///   │   (SwiftUI side) │                  │       (pure AppKit)        │
///   └──────┬───────────┘                  └────────────────────────────┘
///          │ wrapped by
///          ▼
///   ┌─────────────────────────────────────────────┐
///   │      CoordinatedNSHostingController         │
///   │ (NSHostingController bridge — this protocol)│
///   │  Hosts a CoordinatedView in an AppKit VC    │
///   │  and typically implements the coordinator's │
///   │  ViewDelegate for navigation/presentation.  │
///   └─────────────────────────────────────────────┘
/// ```
///
/// In other words:
/// - Pure AppKit screens adopt ``CoordinatedNSViewController``.
/// - Pure SwiftUI views adopt ``CoordinatedView``.
/// - SwiftUI views that need to live inside an AppKit hierarchy are *hosted* by a
///   `CoordinatedNSHostingController`.
///
/// ## Example
/// ```swift
/// // 1. A coordinator sub-protocol that pins down the ViewDelegate.
/// protocol PreferencesCoordinating: CoordinatorProtocol where ViewDelegate == PreferencesViewDelegate {
///     func savePreferences(_ prefs: Preferences)
/// }
///
/// // 2. The AppKit-side actions the screen can request.
/// protocol PreferencesViewDelegate: AnyObject {
///     func dismissPreferences()
///     func showError(_ message: String)
/// }
///
/// // 3. The SwiftUI view.
/// struct PreferencesView: CoordinatedView {
///     let coordinator: any PreferencesCoordinating
///     var body: some View { /* ... */ }
/// }
///
/// // 4. The hosting controller — bridges PreferencesView into AppKit
/// //    and acts as the coordinator's ViewDelegate.
/// final class PreferencesHostingController:
///     NSHostingController<PreferencesView>,
///     CoordinatedNSHostingController,
///     PreferencesViewDelegate
/// {
///     typealias Coordinator = any PreferencesCoordinating
///     typealias RootCoordinatedView = PreferencesView
///
///     let coordinator: (any PreferencesCoordinating)?
///
///     required init(coordinator: (any PreferencesCoordinating)?) {
///         self.coordinator = coordinator
///         super.init(rootView: PreferencesView(coordinator: coordinator!))
///         coordinator?.initialize(with: self)
///     }
///     @MainActor required dynamic init?(coder: NSCoder) { fatalError() }
///
///     // ViewDelegate methods — perform real AppKit work here.
///     func dismissPreferences() { dismiss(nil) }
///     func showError(_ message: String) {
///         let alert = NSAlert(); alert.messageText = message
///         alert.runModal()
///     }
/// }
///
/// // 5. From the rest of AppKit, present it like any other VC:
/// let host = PreferencesHostingController(coordinator: PreferencesCoordinator())
/// window.contentViewController?.presentAsSheet(host)
/// ```
///
/// ## Design Notes
///
/// ### Why the `where` Clause Exists
/// The two constraints in the `where` clause —
/// `Self: NSHostingController<RootCoordinatedView>` and
/// `RootCoordinatedView.Coordinator == Coordinator` —
/// encode the relationship between the three moving parts (host, root view,
/// coordinator) directly in the type system:
///
/// - **`Self: NSHostingController<RootCoordinatedView>`** forces the conformer to
///   be an `NSHostingController` whose root view is the declared
///   ``RootCoordinatedView``. You cannot accidentally conform a plain
///   `NSViewController` or an `NSHostingController` over the wrong view type.
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
/// - **Storyboards / nibs** — `NSHostingController` initializers fired by
///   `init(coder:)` can't pass a coordinator; conformers can store `nil` and inject
///   later.
/// - **Previews and tests** — a placeholder host without a coordinator is useful
///   when only the visual layout is being validated.
///
/// Conformers that always have a coordinator at init time can simply force-unwrap
/// inside their initializer; the optional is a flexibility lever, not a default.
///
/// ### Why `Coordinator` Is Not Constrained to `CoordinatorProtocol`
/// Same reasoning as ``CoordinatedView`` and ``CoordinatedNSViewController``:
/// constraining the associated type directly to ``CoordinatorProtocol`` would
/// force callers to deal with its PAT machinery at the hosting boundary. Leaving
/// it at `Sendable` lets the host hold a refined sub-protocol existential
/// (e.g., `any PreferencesCoordinating`), a stand-in for previews, or a full
/// `CoordinatorProtocol` conformer — all without ceremony.
public protocol CoordinatedNSHostingController
    where Self: NSHostingController<RootCoordinatedView>,
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
    /// performs. See the design note on ``CoordinatedNSHostingController`` for why
    /// this is not constrained to ``CoordinatorProtocol``.
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
