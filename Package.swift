// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FocusLockCore",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "FocusLockCore",
            targets: ["FocusLockCore"]
        ),
    ],
    targets: [
        .target(
            name: "FocusLockCore"
        ),
        .testTarget(
            name: "FocusLockCoreTests",
            dependencies: ["FocusLockCore"]
        ),
    ]
)
