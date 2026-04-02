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
    ],
    targets: [
        .executableTarget(
            name: "Wick",
            dependencies: [
                .product(name: "LanternKit", package: "LanternKit"),
            ]
        ),
    ]
)
