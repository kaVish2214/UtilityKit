<!-- SPDX-License-Identifier: MPL-2.0 -->

# Changelog

All notable changes to UtilityKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-06-27

Initial public release.

### Added
- **`SwiftConcurrency` product.** New library exposing `ConcurrencyContainerProtocol` (`Sendable`-refined, unlabeled `init(_:)` taking `sending State`, `withLock` and `withLockUnchecked`) and `ConcurrencySafeContainer`, which selects the best available backend at runtime (`Mutex` on iOS 18 / macOS 15, `OSAllocatedUnfairLock` on iOS 16 / macOS 13, `NSLock` fallback).
- **`Coordinator` product.** `CoordinatorProtocol` plus SwiftUI (`CoordinatedView`), UIKit (`CoordinatedViewController`, `CoordinatedHostingViewController`), and AppKit (`CoordinatedNSViewController`, `CoordinatedNSHostingController`) integration types.
- **`DependencyResolver` product.** `DependencyResolver`, `DependencyRegistrar`, and `DependencyRegistration` façades over Factory, plus a retroactive `Container: Resolving` conformance.
- **`MultiCastDelegate` product.** `MultiCastDelegate`, `DelegateMultiCasting`, `DelegateSubscription`, and a thread-safe `DelegateSubscriptionHandle` implementation.
- Comprehensive `README.md` covering every product, including design notes, public-surface tables, and end-to-end usage snippets.
- Swift Testing test target (`UtilityKitTests`) covering every product.
- Mozilla Public License 2.0 (`LICENSE`) with SPDX `MPL-2.0` headers on every source, test, and helper file.
- `CONTRIBUTING.md` and `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1).

[0.1.0]: https://github.com/kaVish2214/UtilityKit/releases/tag/0.1.0
