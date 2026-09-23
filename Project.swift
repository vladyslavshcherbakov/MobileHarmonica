import ProjectDescription

let project = Project(
    name: "MobileHarmonica",
    options: .options(automaticSchemesOptions: .disabled),
    packages: [
        .package(path: "Core"),
    ],
    settings: .settings(
        base: [
            "SWIFT_VERSION": "6",
            "CODE_SIGN_STYLE": "Automatic",
            "DEVELOPMENT_TEAM": "",
        ]
    ),
    targets: [
        .target(
            name: "MobileHarmonica",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.vladyslavshcherbakov.mobileharmonica",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .dictionary([
                "CFBundleDevelopmentRegion": "$(DEVELOPMENT_LANGUAGE)",
                "CFBundleExecutable": "$(EXECUTABLE_NAME)",
                "CFBundleIdentifier": "$(PRODUCT_BUNDLE_IDENTIFIER)",
                "CFBundleInfoDictionaryVersion": "6.0",
                "CFBundleName": "$(PRODUCT_NAME)",
                "CFBundlePackageType": "$(PRODUCT_BUNDLE_PACKAGE_TYPE)",
                "CFBundleShortVersionString": "1.0",
                "CFBundleVersion": "1",
                "LSRequiresIPhoneOS": true,
                "CADisableMinimumFrameDurationOnPhone": true,
                "UILaunchScreen": [:],
                "UISupportedInterfaceOrientations": [
                    "UIInterfaceOrientationLandscapeLeft",
                    "UIInterfaceOrientationLandscapeRight",
                ],
            ]),
            sources: [.glob("Apps/iOS/**", excluding: ["Apps/iOS/Tests/**", "Apps/iOS/Scores/**"])],
            resources: [
                .folderReference(path: "Resources/Samples"),
                .folderReference(path: "Apps/iOS/Scores"),
            ],
            dependencies: [
                .package(product: "HarmonicaCore"),
            ]
        ),
        .target(
            name: "MobileHarmonicaTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.vladyslavshcherbakov.MobileHarmonicaTests",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .default,
            sources: ["Apps/iOS/Tests/**", "Core/Tests/HarmonicaCoreTests/**"],
            dependencies: [
                .target(name: "MobileHarmonica"),
                .package(product: "HarmonicaCoreTestSupport"),
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "MobileHarmonica",
            buildAction: .buildAction(targets: ["MobileHarmonica"]),
            testAction: .targets(["MobileHarmonicaTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug, executable: .executable("MobileHarmonica")),
            archiveAction: .archiveAction(configuration: .release)
        ),
    ]
)
