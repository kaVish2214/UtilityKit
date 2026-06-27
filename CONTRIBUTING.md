<!-- SPDX-License-Identifier: MPL-2.0 -->

# Contributing to UtilityKit

Thanks for your interest in contributing! UtilityKit is licensed under the [Mozilla Public License 2.0](LICENSE), and by submitting a contribution you agree it will be released under the same license (inbound = outbound).

## Getting Started

```bash
git clone https://github.com/kaVish2214/UtilityKit.git
cd UtilityKit
swift build
swift test
```

The package targets **iOS 14+** and **macOS 10.15+** with **Swift 6.3** (language mode 6).

## Project Layout

- `Sources/MultiCastDelegate/` — type-safe one-to-many delegate pattern.
- `Sources/DependencyResolver/` — Factory façade for DI registration and resolution.
- `Sources/Coordinator/` — SwiftUI / UIKit / AppKit coordinator architecture.
- `Sources/SwiftConcurrency/` — OS-adaptive lock-box (`Mutex` / `OSAllocatedUnfairLock` / `NSLock`).
- `Tests/UtilityKitTests/` — Swift Testing target covering every product.

See the [README](README.md) for the public API of each product.

## Filing Issues

- **Bugs** — include the package version (or commit SHA), OS version, Swift toolchain version, and a minimal reproducer.
- **Features** — describe the use case and how it fits the existing four products; UtilityKit prefers small, focused additions over broad ones.

## Pull Requests

1. **Branch from `main`.**
2. **One concern per PR.** Smaller PRs ship faster.
3. **Tests are required** for new behaviour or bug fixes. Run `swift test` locally and ensure all suites pass before pushing.
4. **Docs** — public symbols get DocC comments; user-facing changes update [`README.md`](README.md) and add an entry to [`CHANGELOG.md`](CHANGELOG.md) under `[Unreleased]`.
5. **License headers** — every new Swift file starts with the standard MPL-2.0 header used elsewhere in the repo. Copy the header from any existing file (for example `Sources/SwiftConcurrency/Interface/ConcurrencyContainerProtocol.swift`).
6. **No unrelated changes.** Formatting passes, renames, and unrelated refactors belong in their own PRs.

## Coding Style

- 4-space indentation.
- `PascalCase` for types, `camelCase` for properties and methods.
- Prefer `let` over `var`; avoid force unwrapping.
- Swift Concurrency (`async`/`await`, structured concurrency) over Combine wherever there's a choice.
- Tests use the [Swift Testing](https://developer.apple.com/documentation/testing/) framework — `@Suite` / `@Test` / `#expect`, not XCTest.
- Keep public API surfaces small and orthogonal; prefer composition over inheritance.

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). By participating, you agree to abide by its terms.
