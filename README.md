# UtilityKit

[![License: MPL 2.0](https://img.shields.io/badge/License-MPL_2.0-brightgreen.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/Swift-6.3-orange.svg)](https://swift.org)
[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2014%2B%20%7C%20macOS%2010.15%2B-blue.svg)](https://developer.apple.com)

A Swift Package that bundles four small, focused libraries used across iOS and macOS apps:

| Product              | What it gives you                                                                                  |
|----------------------|----------------------------------------------------------------------------------------------------|
| `MultiCastDelegate`  | A type-safe, thread-safe, one-to-many delegate pattern with per-subscriber dispatch queues.        |
| `DependencyResolver` | A thin protocol façade over [Factory](https://github.com/hmlongco/Factory) for DI registration & resolution. |
| `Coordinator`        | A coordinator-driven UI architecture that works for SwiftUI, UIKit, AppKit, and SwiftUI-in-UIKit.  |
| `SwiftConcurrency`   | An OS-adaptive lock-box (`Mutex` / `OSAllocatedUnfairLock` / `NSLock`) behind one tiny protocol.   |

- **Swift tools:** 6.3
- **Swift language mode:** 6
- **Platforms:** iOS 14+, macOS 10.15+
- **Dependencies:** [Factory](https://github.com/hmlongco/Factory) (`upToNextMajor` from 2.4.3)
- **License:** Mozilla Public License 2.0 (MPL-2.0)

## Installation

Add UtilityKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/kaVish2214/UtilityKit.git", from: "0.1.0")
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "MultiCastDelegate",  package: "UtilityKit"),
            .product(name: "DependencyResolver", package: "UtilityKit"),
            .product(name: "Coordinator",        package: "UtilityKit"),
            .product(name: "SwiftConcurrency",   package: "UtilityKit")
        ]
    )
]
```

Each product is independently linkable — you only pay for what you import.

---

## 1. `MultiCastDelegate`

A type-safe, **one-to-many** delegate pattern. Subscribers are stored **weakly** and each one receives callbacks on its own `DispatchQueue`. All registration and broadcast operations are thread-safe.

### Public Surface

| Symbol                        | Role                                                                                                 |
|-------------------------------|------------------------------------------------------------------------------------------------------|
| `MultiCastDelegate`           | Base protocol every domain-specific delegate must refine. Requires `AnyObject & Sendable`.           |
| `DelegateMultiCasting`        | Protocol you adopt on the object that **owns** the subscriber list (the multicaster).                |
| `DelegateSubscription`        | Protocol describing a subscriber store (subscribe / unsubscribe / queue lookup).                     |
| `DelegateSubscriptionHandle`  | Ready-made, thread-safe `DelegateSubscription` backed by `NSHashTable.weakObjects()` + `NSLock`.     |

### What You Must Provide vs. What You Get For Free

When you adopt `DelegateMultiCasting`, the **only** requirement you implement is the `delegates` property:

```swift
let delegates: any DelegateSubscription = DelegateSubscriptionHandle()
```

Everything else — `subscribeDelegate(_:receive:)`, `unsubscribeDelegate(_:)`, `invoke(invocation:)` — is provided by protocol extension and forwards to that handle. Likewise, if you adopt `DelegateSubscription` directly you must implement `subscribers`, `subscribe(_:receive:)`, `unsubscribe(_:)`, and `queue(for:)` — but the shipped `DelegateSubscriptionHandle` covers that completely.

### Design Choices

- **Weak storage.** `DelegateSubscriptionHandle` uses `NSHashTable.weakObjects()` plus an `NSMapTable.weakToStrongObjects()` for queues — subscribers don't need to manually unregister on deinit.
- **Per-subscriber queue.** Each subscriber registers with the queue it wants callbacks delivered on; the multicaster never assumes "main".
- **Asynchronous delivery.** The default `invoke(invocation:)` dispatches `async` to each subscriber's registered queue — broadcasting never blocks the caller, and the weak reference may have been zeroed by the time the closure runs (hence the `Delegate?` parameter).
- **Reverse-iteration broadcast.** Subscribers receive callbacks in **reverse registration order**. This makes it safe for a subscriber to unsubscribe during a broadcast without disturbing the indices of subscribers still pending delivery.
- **Existential storage, typed API.** `DelegateSubscription` is existential over `any MultiCastDelegate` to allow heterogeneous storage, while `DelegateMultiCasting` exposes a typed `Delegate` associated type so the call site stays type-safe.
- **Class-only (`AnyObject`).** Subscriber stores hold shared mutable state — value types would diverge per copy and break invariants.
- **Foundation-only.** No UIKit/AppKit/SwiftUI imports — available on every platform the package supports.

### Objective-C Interop

`MultiCastDelegate` requires only `AnyObject` so pure-Swift classes can adopt it without Objective-C overhead. If your delegate protocol needs `@objc` methods or optional requirements, refine it to also require `NSObjectProtocol`:

```swift
@objc protocol VideoPlayerDelegate: MultiCastDelegate, NSObjectProtocol {
    @objc optional func playerDidPause()
}
```

### Usage

```swift
// 1. Define a domain-specific delegate.
protocol DownloadDelegate: MultiCastDelegate {
    func downloadDidStart(_ url: URL)
    func downloadDidFinish(_ url: URL, data: Data)
}

// 2. Make the producer adopt DelegateMultiCasting.
final class Downloader: DelegateMultiCasting, @unchecked Sendable {
    typealias Delegate = any DownloadDelegate
    let delegates: any DelegateSubscription = DelegateSubscriptionHandle()

    func start(_ url: URL) {
        invoke { $0?.downloadDidStart(url) }
        // ... async work ...
        invoke { $0?.downloadDidFinish(url, data: data) }
    }
}

// 3. Subscribe / unsubscribe.
downloader.subscribeDelegate(observer, receive: .main)
downloader.unsubscribeDelegate(observer)
```

Default implementations of `subscribeDelegate(_:receive:)`, `unsubscribeDelegate(_:)`, and `invoke(invocation:)` are provided automatically — conformers only declare the `delegates` property.

---

## 2. `DependencyResolver`

A thin protocol façade over [Factory](https://github.com/hmlongco/Factory). It lets call sites resolve dependencies without importing Factory directly, and gives feature modules a single, declarative entry point for batch-registering their factories.

### Public Surface

| Symbol                    | Role                                                                                                |
|---------------------------|-----------------------------------------------------------------------------------------------------|
| `DependencyResolver`      | Adopt to gain `resolved(_:)` / `resolver` backed by `Container.shared`.                             |
| `DependencyRegistrar`     | Adopt on a module to expose `static func registerDependencies(_:)` for batch registration.          |
| `DependencyRegistration`  | Adopt to define a **parameterized** registration (runtime parameter required to resolve).           |
| `ParameterRegistry`       | Alias for Factory's `FactoryModifying` (gives access to `.cached`, `.singleton`, etc.).             |
| `ParameterRegistration`   | Alias for Factory's `ParameterFactory<P, T>`.                                                       |
| `Container: Resolving`    | Retroactive conformance so `Container.shared` plugs straight into the resolver API.                 |

### Design Choices

- **Façade over Factory.** Consumers see protocols like `Resolver` and `ParameterRegistry` instead of importing Factory — keeping the dependency swappable and the import surface small.
- **Shared `Container`.** Default implementations resolve through `Container.shared`, but every protocol method takes an explicit `Resolver`, so tests and previews can pass a scoped container.
- **Three roles, three protocols.**
  - `DependencyResolver` is for **consumers** that need to pull dependencies out.
  - `DependencyRegistrar` is for **modules** that need to put dependencies in.
  - `DependencyRegistration` is for **registrations that need runtime parameters** (e.g., a detail screen that needs an ID).

### Usage

**Resolving:**
```swift
final class ProfileViewModel: DependencyResolver {
    func load() {
        let service: ProfileService? = resolved()   // type inferred
        // ... use service ...
    }
}
```

**Batch registration:**
```swift
enum NetworkModule: DependencyRegistrar {
    static func registerDependencies(_ resolver: Resolver) {
        // Register factories on `resolver` (typically Container.shared).
    }
}

// At app launch:
NetworkModule.registerDependencies(Container.shared)
```

**Parameterized registration:**
```swift
struct DetailRegistration: DependencyRegistration {
    typealias Parameter = String
    typealias Registration = ParameterFactory<String, DetailViewModel>

    func registration(for resolver: Resolver) -> Registration { /* ... */ }

    func resolve(parameter: String, resolver: Resolver) -> DetailViewModel? {
        registration(for: resolver).resolve(parameter)
    }
}
```

---

## 3. `Coordinator`

A coordinator-driven architecture for screen-level logic. The coordinator owns business logic, state, and I/O; the view (SwiftUI or UIKit/AppKit) only renders state and forwards user input. UIKit/AppKit-side actions (push, present, dismiss) are delegated back to the hosting view controller through a `ViewDelegate`.

### Public Surface

| Symbol                              | Platform                  | Role                                                                                             |
|-------------------------------------|---------------------------|--------------------------------------------------------------------------------------------------|
| `CoordinatorProtocol`               | All                       | The brain of a screen. Holds state, runs logic, calls into its `ViewDelegate` for UI-side work.  |
| `CoordinatedView`                   | All                       | SwiftUI `View` that holds a coordinator and forwards user input to it.                           |
| `CoordinatedViewController`         | iOS (`canImport(UIKit)`)  | UIKit `UIViewController` that holds a coordinator.                                               |
| `CoordinatedNSViewController`       | macOS (`canImport(AppKit)`) | AppKit `NSViewController` that holds a coordinator.                                            |
| `CoordinatedHostingViewController`  | iOS (`canImport(UIKit)`)  | `UIHostingController` bridge that hosts a `CoordinatedView` inside a UIKit nav stack.            |
| `CoordinatedNSHostingController`    | macOS (`canImport(AppKit)`) | `NSHostingController` bridge that hosts a `CoordinatedView` inside an AppKit hierarchy.        |

Each platform-specific protocol is wrapped in a `#if canImport(...)` guard, so importing `Coordinator` from a non-matching platform simply omits those symbols rather than failing to build.

### Architecture

```
   ┌─────────────────┐   user input    ┌────────────────────┐
   │   SwiftUI View  │ ──────────────▶ │    Coordinator     │
   │ (or UIKit VC)   │                 │ (business logic +  │
   │                 │ ◀────────────── │   state + I/O)     │
   └─────────────────┘   state/output  └─────────┬──────────┘
                                                 │
                                  navigate / present / dismiss
                                                 ▼
                                       ┌────────────────────┐
                                       │   ViewDelegate     │
                                       │ (implemented by    │
                                       │  UIKit/AppKit VC)  │
                                       └────────────────────┘
```

- **View → Coordinator:** user input goes here. Method calls, not bindings.
- **Coordinator → ViewDelegate:** anything that requires a `UIViewController`/`NSViewController` reference — navigation, presentation, alerts.
- **ViewDelegate implementer:** the hosting `UIViewController` / `NSViewController` (in UIKit/AppKit) or the `*HostingViewController` (when bridging SwiftUI into UIKit/AppKit).

### Design Choices

- **`Coordinator` associated type is unconstrained beyond `Sendable`.** `CoordinatorProtocol` is a PAT (it has its own `ViewDelegate` associated type). Constraining the view's `Coordinator` directly to `CoordinatorProtocol` would force every call site to deal with PAT machinery. Leaving it open lets views hold a refined sub-protocol existential (e.g., `any LoginCoordinating`), a preview/test stand-in, or a full conformer — all without ceremony.
- **`CoordinatedHostingViewController` enforces wiring at the type level.** Its `where` clause requires `Self: UIHostingController<RootCoordinatedView>` and `RootCoordinatedView.Coordinator == Coordinator`, so mismatches surface as compile errors, not runtime crashes.
- **Optional coordinator in hosting init.** `init(coordinator: Coordinator?)` supports lazy DI, `init(coder:)` paths, and previews. Conformers that always have one at init time can simply force-unwrap.
- **`weak var viewDelegate`.** The UIKit/AppKit host owns the coordinator (directly or transitively); holding the delegate strongly would create a retain cycle.

### What Each Protocol Requires

| Protocol                              | Associated Types                                | Required Members                                         |
|---------------------------------------|-------------------------------------------------|----------------------------------------------------------|
| `CoordinatorProtocol`                 | `ViewDelegate: Sendable`                        | `var viewDelegate: ViewDelegate? { get }`, `func initialize(with: ViewDelegate)` |
| `CoordinatedView`                     | `Coordinator: Sendable`                         | `var coordinator: Coordinator { get }`, `init(coordinator:)` |
| `CoordinatedViewController`           | `Coordinator: Sendable`                         | `var coordinator: Coordinator { get }`                   |
| `CoordinatedNSViewController`         | `Coordinator: Sendable`                         | `var coordinator: Coordinator { get }`                   |
| `CoordinatedHostingViewController`    | `RootCoordinatedView: CoordinatedView`, `Coordinator: Sendable` | `init(coordinator: Coordinator?)` (no `coordinator` getter — `where`-clause already pins it) |
| `CoordinatedNSHostingController`      | `RootCoordinatedView: CoordinatedView`, `Coordinator: Sendable` | `init(coordinator: Coordinator?)`                   |

The hosting controllers also carry two `where`-clause constraints that the conformer must satisfy:
- `Self: UIHostingController<RootCoordinatedView>` (or `NSHostingController<…>`)
- `RootCoordinatedView.Coordinator == Coordinator`

### Recommended Pattern

Define a sub-protocol of `CoordinatorProtocol` that pins down `ViewDelegate`, then have views hold it as an existential:

```swift
protocol LoginCoordinating: CoordinatorProtocol where ViewDelegate == LoginViewDelegate {
    func login(email: String, password: String)
}

protocol LoginViewDelegate: AnyObject {
    func navigateToHome()
    func showError(_ message: String)
}
```

### Usage — Concrete `CoordinatorProtocol` Conformer

The coordinator is where business logic lives. It receives user input from the view, runs the work, and routes UIKit/AppKit-side actions through `viewDelegate`:

```swift
final class LoginCoordinator: LoginCoordinating {
    typealias ViewDelegate = LoginViewDelegate

    weak var viewDelegate: LoginViewDelegate?
    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    func initialize(with viewDelegate: LoginViewDelegate) {
        self.viewDelegate = viewDelegate
        // Kick off any "screen appeared" work here.
    }

    // Called by the view on user input.
    func login(email: String, password: String) {
        Task {
            do {
                try await authService.signIn(email, password)
                await viewDelegate?.navigateToHome()       // UIKit-side action
            } catch {
                await viewDelegate?.showError(error.localizedDescription)
            }
        }
    }
}
```

### Usage — SwiftUI hosted in a UIKit nav stack

```swift
// SwiftUI view.
struct LoginView: CoordinatedView {
    let coordinator: any LoginCoordinating
    var body: some View { /* ... */ }
}

// Hosting controller — bridges LoginView into UIKit and implements ViewDelegate.
final class LoginHostingController:
    UIHostingController<LoginView>,
    CoordinatedHostingViewController,
    LoginViewDelegate
{
    typealias Coordinator = any LoginCoordinating
    typealias RootCoordinatedView = LoginView

    let coordinator: (any LoginCoordinating)?

    required init(coordinator: (any LoginCoordinating)?) {
        self.coordinator = coordinator
        super.init(rootView: LoginView(coordinator: coordinator!))
        coordinator?.initialize(with: self)
    }
    @MainActor required dynamic init?(coder: NSCoder) { fatalError() }

    func navigateToHome() {
        navigationController?.pushViewController(HomeViewController(), animated: true)
    }
    func showError(_ message: String) {
        present(UIAlertController.error(message), animated: true)
    }
}
```

### Usage — Pure UIKit

```swift
final class LoginViewController: UIViewController, CoordinatedViewController, LoginViewDelegate {
    let coordinator: any LoginCoordinating

    init(coordinator: any LoginCoordinating) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        coordinator.initialize(with: self)
    }

    func navigateToHome() { /* push */ }
    func showError(_ message: String) { /* present alert */ }
}
```

### Usage — Pure AppKit

```swift
final class PreferencesViewController: NSViewController, CoordinatedNSViewController, PreferencesViewDelegate {
    let coordinator: any PreferencesCoordinating

    init(coordinator: any PreferencesCoordinating) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        coordinator.initialize(with: self)
    }

    func showAdvancedOptions() { presentAsSheet(AdvancedOptionsViewController(coordinator: ...)) }
    func showError(_ message: String) { /* NSAlert */ }
}
```

### Usage — SwiftUI hosted in an AppKit hierarchy

```swift
// SwiftUI view.
struct PreferencesView: CoordinatedView {
    let coordinator: any PreferencesCoordinating
    var body: some View { /* ... */ }
}

// Hosting controller — bridges PreferencesView into AppKit and implements ViewDelegate.
final class PreferencesHostingController:
    NSHostingController<PreferencesView>,
    CoordinatedNSHostingController,
    PreferencesViewDelegate
{
    typealias Coordinator = any PreferencesCoordinating
    typealias RootCoordinatedView = PreferencesView

    let coordinator: (any PreferencesCoordinating)?

    required init(coordinator: (any PreferencesCoordinating)?) {
        self.coordinator = coordinator
        super.init(rootView: PreferencesView(coordinator: coordinator!))
        coordinator?.initialize(with: self)
    }
    @MainActor required dynamic init?(coder: NSCoder) { fatalError() }

    func dismissPreferences() { dismiss(nil) }
    func showError(_ message: String) {
        let alert = NSAlert(); alert.messageText = message
        alert.runModal()
    }
}

// From the rest of AppKit:
let host = PreferencesHostingController(coordinator: PreferencesCoordinator())
window.contentViewController?.presentAsSheet(host)
```

### What Goes Where

A quick rule for keeping the layers clean:

|                                                       | Coordinator | View / VC | ViewDelegate |
|-------------------------------------------------------|:-----------:|:---------:|:------------:|
| User input (taps, gestures, text edits)               |   ✅ receives    | forwards | ❌ |
| Business logic, networking, persistence               |     ✅      |     ❌    |       ❌      |
| State the view renders                                | ✅ owns it  | ✅ reads  |       ❌      |
| Navigation (push, pop, present, dismiss)              | ✅ decides  |     ❌    | ✅ executes  |
| System UI (alerts, action sheets, share sheets, NSAlert) | ✅ requests |  ❌    | ✅ executes  |

---

## 4. `SwiftConcurrency`

An OS-adaptive lock-box for protecting a single piece of mutable state. Pick the protocol; the concrete container picks the fastest backend available on the running OS.

### Public Surface

| Symbol                          | Role                                                                                                     |
|---------------------------------|----------------------------------------------------------------------------------------------------------|
| `ConcurrencyContainerProtocol`  | The protocol contract: one piece of state, mutated under exclusive access via `withLock` / `withLockUnchecked`. |
| `ConcurrencySafeContainer`      | Default implementation. Selects the best backend at runtime — `Mutex` → `OSAllocatedUnfairLock` → `NSLock`. |

### Backend Selection

| Backend                  | Selected on                | Notes                                              |
|--------------------------|----------------------------|----------------------------------------------------|
| `Mutex` (Synchronization)| iOS 18+ / macOS 15+        | Preferred when available — fast and non-blocking.  |
| `OSAllocatedUnfairLock`  | iOS 16+ / macOS 13+        | OS-allocated unfair lock.                          |
| `NSLock` fallback        | All supported deployments  | Universal fallback (`LegacyConcurrencySafe`).      |

The selection is transparent to callers: they only ever see the protocol surface.

### Two Mutation Methods

| Method                    | Sendable enforcement?                                | When to use                                                                 |
|---------------------------|------------------------------------------------------|------------------------------------------------------------------------------|
| `withLock(_:)`            | Yes — `@Sendable` closure and `Sendable` return.     | **Default.** Compiler-checked safety.                                       |
| `withLockUnchecked(_:)`   | No.                                                  | When you must return or mutate a non-`Sendable` value (e.g., a legacy class). |

### Initialization

There is a single entry point: `init(_:)`. It takes `sending State`, so the caller transfers ownership of the value into the container. This works equally well for `Sendable` and non-`Sendable` state — `Sendable` values trivially satisfy `sending`, and non-`Sendable` values are made safe by the transfer.

### Protocol-Level `Sendable`

`ConcurrencyContainerProtocol` refines `Sendable`:

```swift
public protocol ConcurrencyContainerProtocol<State>: Sendable { … }
```

Every conformer is therefore safe to capture by `Task`s, store in actors, or pass between threads. The lock inside each conformer makes that promise true; refining the protocol on `Sendable` surfaces it at the type level so callers don't have to opt in (or assert it) at each call site.

### Why `OSAllocatedUnfairLock` Conforms Directly but `Mutex` Needs a Wrapper

`OSAllocatedUnfairLock` happens to ship `withLock` / `withLockUnchecked` in exactly the protocol's shape, so its conformance is a one-line bridge over the init label:

```swift
@available(iOS 16.0, macOS 13.0, *)
extension OSAllocatedUnfairLock: ConcurrencyContainerProtocol {
    public init(_ state: sending State) { self.init(uncheckedState: state) }
}
```

`Mutex` (from `Synchronization`) can't take the same path because it diverges on four axes:

| Aspect              | `OSAllocatedUnfairLock`             | `Mutex`                                                   |
|---------------------|-------------------------------------|-----------------------------------------------------------|
| Copyability         | `Copyable`                          | `~Copyable` — can't conform to a `Copyable` protocol.     |
| Init label          | `init(uncheckedState:)`             | `init(_:)` — bridged by the extension above.              |
| `withLock` body     | `(inout State)`                     | `(inout sending Value)` + typed throws + `~Copyable` result. |
| `withLockUnchecked` | Native method                       | Doesn't exist.                                            |

The `~Copyable` difference alone is fatal — the rest only compounds it. So `Mutex` is wrapped by `MutexBox` (a `final class`, hence `Copyable`) that re-exposes the API under the protocol's signatures.

### Design Choices

- **One contract, many backends.** The runtime branch lives entirely inside `ConcurrencySafeContainer.init`. Call sites never see `#available` checks.
- **Protocol refines `Sendable`.** Conformers are guaranteed safe to cross isolation boundaries; the lock is what makes that promise sound.
- **A single initializer.** `init(_:)` covers every case — `Sendable` or not. One entry point keeps the surface tiny and removes any ambiguity about which init is "the right one."
- **`sending` for ownership transfer.** Taking `sending State` means the caller hands the value to the container exclusively. Once constructed, the value is reachable only through `withLock` / `withLockUnchecked`, which is what makes the container a safe concurrency boundary even when `State` isn't `Sendable`.
- **`Sendable` is synthesized — no `@unchecked` needed.** Because `ConcurrencyContainerProtocol` refines `Sendable`, the existential `any ConcurrencyContainerProtocol<State>` stored as the backend is itself `Sendable`. That's the struct's only stored field, so the compiler synthesizes `Sendable` for the container automatically — even when `State` isn't `Sendable`, since the value lives behind the backend's lock and never on the struct directly.

### Usage

**`Sendable` state — the common case:**
```swift
let counter = ConcurrencySafeContainer<Int>(0)

counter.withLock { state in
    state += 1
}

let snapshot = counter.withLock { state in state }   // 1
```

**Non-`Sendable` state (legacy classes, UIKit objects):**
```swift
let cache = ConcurrencySafeContainer<NSMutableDictionary>(NSMutableDictionary())

cache.withLockUnchecked { dict in
    dict["key"] = "value"
}
```

**Concurrent writes from multiple tasks:**
```swift
let totals = ConcurrencySafeContainer<[String: Int]>([:])

await withTaskGroup(of: Void.self) { group in
    for word in words {
        group.addTask {
            totals.withLock { dict in
                dict[word, default: 0] += 1
            }
        }
    }
}
```

---

## Testing

The package ships a `UtilityKitTests` test target that exercises every product (see `Tests/UtilityKitTests/CoordinatorTests`, `DependencyResolverTests`, `MultiCastDelegateTests`, `SwiftConcurrencyTests`). Tests are written with the [Swift Testing](https://developer.apple.com/documentation/testing/) framework.

Run them from Xcode or the command line:

```bash
swift test
```

---

## Contributing

Bug reports, feature requests, and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for community expectations. A running list of changes lives in [CHANGELOG.md](CHANGELOG.md).

## License

UtilityKit is licensed under the Mozilla Public License 2.0 (MPL-2.0). Copyright (c) 2026 kaVi Gevariya (@kaVish2214).

You may use, modify, distribute, and sell modified versions of this package. Modifications to MPL-covered source files must remain available under MPL-2.0. See [LICENSE](LICENSE) for the full license terms.

