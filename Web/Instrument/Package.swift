// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "HarmonicaWasm",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "HarmonicaWasm", targets: ["HarmonicaWasm"])
    ],
    dependencies: [
        .package(path: "../../Core")
    ],
    targets: [
        .executableTarget(
            name: "HarmonicaWasm",
            dependencies: [.product(name: "HarmonicaCore", package: "Core")],
            swiftSettings: [.enableExperimentalFeature("Extern")]
        )
    ]
)
