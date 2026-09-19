// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "HarmonicaCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "HarmonicaCore", targets: ["HarmonicaCore"]),
        .library(name: "HarmonicaCoreTestSupport", targets: ["HarmonicaCoreTestSupport"])
    ],
    targets: [
        .target(name: "HarmonicaCore"),
        .target(name: "HarmonicaCoreTestSupport", dependencies: ["HarmonicaCore"]),
        .testTarget(
            name: "HarmonicaCoreTests",
            dependencies: ["HarmonicaCore", "HarmonicaCoreTestSupport"]
        )
    ]
)
