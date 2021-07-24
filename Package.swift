// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IndomioNetwork",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "IndomioNetwork",
            targets: ["IndomioNetwork"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "IndomioNetwork",
            dependencies: []),
        .testTarget(
            name: "IndomioNetworkTests",
            dependencies: ["IndomioNetwork"]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
