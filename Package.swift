// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RealHTTP",
    platforms: [
        .iOS(.v13), .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "RealHTTP",
            targets: ["RealHTTP"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Specify where to download the compiled swiftlint tool from
        // Temporary disabled due to a bug in Xcode 13.4.1 and SPM plugins
        // <https://forums.swift.org/t/spm-plugin-with-binary-target-high-cpu-usage/59535>
        // <https://github.com/immobiliare/RealHTTP/issues/60>
        /*.binaryTarget(
            name: "SwiftLintBinary",
            url: "https://github.com/juozasvalancius/SwiftLint/releases/download/spm-accommodation/SwiftLintBinary-macos.artifactbundle.zip",
            checksum: "cdc36c26225fba80efc3ac2e67c2e3c3f54937145869ea5dbcaa234e57fc3724"
        ),
        // Define the SPM plugin
        .plugin(
            name: "SwiftLintXcode",
            capability: .buildTool(),
            dependencies: ["SwiftLintBinary"]
        ),*/
        .target(
            name: "RealHTTP",
            dependencies: []
            // plugins: ["SwiftLintXcode"]
        ),
        .testTarget(
            name: "RealHTTPTests",
            dependencies: ["RealHTTP"],
            resources: [
                .copy("Resources/test_rawdata.png"),
                .copy("Resources/mac_icon.jpg")
            ]),
    ]
)
