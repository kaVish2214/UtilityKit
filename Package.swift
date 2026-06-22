// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

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
            path: "Sources/MultiCastDelegate"
        ),
        .target(
            name: "DependencyResolver",
            dependencies: [
                .product(name: "Factory", package: "Factory")
            ],
            path: "Sources/DependencyResolver"
        ),
        .target(
            name: "Coordinator",
            path: "Sources/Coordinator"
        ),
        .target(
            name: "SwiftConcurrency",
            path: "Sources/SwiftConcurrency"
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
