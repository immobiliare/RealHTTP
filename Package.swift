// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IndomioHTTP",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "IndomioHTTP",
            targets: ["IndomioHTTP"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "IndomioHTTP",
            dependencies: []),
        .testTarget(
            name: "IndomioHTTPTests",
            dependencies: ["IndomioHTTP"]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
