// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Bradel",
    platforms: [
        .iOS(.v12),
        .tvOS(.v12)
    ],
    products: [
        .library(
            name: "Bradel",
            targets: ["Bradel"]),
    ],
    targets: [
        .target(
            name: "Bradel",
            dependencies: []),
        .testTarget(
            name: "BradelTests",
            dependencies: ["Bradel"]),
    ]
)
