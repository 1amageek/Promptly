// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Promptly",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(
            name: "Promptly",
            targets: ["Promptly"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Promptly",
            dependencies: [
            ]
        ),
        .testTarget(
            name: "PromptlyTests",
            dependencies: ["Promptly"]
        ),
    ]
)
