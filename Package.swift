// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Wick",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
    ],
    dependencies: [
        .package(path: "../LanternKit"),
        .package(path: "../SplitView"),
    ],
    targets: [
        .executableTarget(
            name: "Wick",
            dependencies: [
                .product(name: "LanternKit", package: "LanternKit"),
                .product(name: "SplitView", package: "SplitView"),
            ]
        ),
    ]
)
