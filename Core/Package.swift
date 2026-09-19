// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "HarmonicaCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "HarmonicaCore", targets: ["HarmonicaCore"]),
        .library(name: "HarmonicaCoreTestSupport", targets: ["HarmonicaCoreTestSupport"]),
        .executable(name: "HarmonicaWasm", targets: ["HarmonicaWasm"])
    ],
    targets: [
        .target(name: "HarmonicaCore"),
        .target(name: "HarmonicaCoreTestSupport", dependencies: ["HarmonicaCore"]),
        .executableTarget(
            name: "HarmonicaWasm",
            dependencies: ["HarmonicaCore"],
            swiftSettings: [
                .unsafeFlags(["-Xclang-linker", "-mexec-model=reactor"], .when(platforms: [.wasi]))
            ]
        ),
        .testTarget(
            name: "HarmonicaCoreTests",
            dependencies: ["HarmonicaCore", "HarmonicaCoreTestSupport"]
        )
    ]
)
