// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RealHTTP",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "RealHTTP",
            targets: ["RealHTTP"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "RealHTTP",
            dependencies: []),
        .testTarget(
            name: "RealHTTPTests",
            dependencies: ["RealHTTP"]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
