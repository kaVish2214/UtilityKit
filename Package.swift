// swift-tools-version: 6.3
// Copyright (c) 2026 kaVi Gevariya (@kaVish2214)
//
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file, You can
// obtain one at https://mozilla.org/MPL/2.0/.
// SPDX-License-Identifier: MPL-2.0

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .unsafeFlags([
        "-Xfrontend", "-warn-long-function-bodies=100",
        "-Xfrontend", "-warn-long-expression-type-checking=100"
    ])
]

let package = Package(
    name: "UtilityKit",
    platforms: [
        .iOS(.v14),
        .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MultiCastDelegate",
            targets: [
                "MultiCastDelegate",
            ]
        ),
        .library(
            name: "DependencyResolver",
            targets: [
                "DependencyResolver"
            ]
        ),
        .library(
            name: "Coordinator",
            targets: [
                "Coordinator"
            ]
        ),
        .library(
            name: "SwiftConcurrency",
            targets: [
                "SwiftConcurrency"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/hmlongco/Factory", .upToNextMajor(from: .init(stringLiteral: "2.4.3"))),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MultiCastDelegate",
            path: "Sources/MultiCastDelegate",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "DependencyResolver",
            dependencies: [
                .product(name: "Factory", package: "Factory")
            ],
            path: "Sources/DependencyResolver",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "Coordinator",
            path: "Sources/Coordinator",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SwiftConcurrency",
            path: "Sources/SwiftConcurrency",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "UtilityKitTests",
            dependencies: [
                "MultiCastDelegate",
                "DependencyResolver",
                "Coordinator",
                "SwiftConcurrency"
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
