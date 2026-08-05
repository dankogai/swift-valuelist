// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ValueList",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ValueList",
            targets: ["ValueList"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ValueList"
        ),
        .testTarget(
            name: "ValueListTests",
            dependencies: ["ValueList"]
        ),
        // Benchmarks are a standalone executable so CI never runs them —
        // the workflow only invokes `swift test`. Run locally with:
        //   swift run -c release Benchmarks [n]
        .executableTarget(
            name: "Benchmarks",
            dependencies: ["ValueList"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
