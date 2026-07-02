import ProjectDescription

/// Tuist project for the Kai app. The four feature packages live under Packages/
/// as local Swift packages; the app target links their products. Regenerate the
/// Xcode project with `tuist generate` (the generated .xcodeproj is git-ignored).
let project = Project(
    name: "Kai",
    packages: [
        .local(path: "Packages/KaiCore"),
        .local(path: "Packages/KaiFSRS"),
        .local(path: "Packages/KaiAI"),
        .local(path: "Packages/KaiServices"),
        .local(path: "Packages/KaiUI"),
    ],
    settings: .settings(
        base: [
            "SWIFT_VERSION": "6.0",
        ]
    ),
    targets: [
        .target(
            name: "Kai",
            destinations: .iOS,
            product: .app,
            bundleId: "app.yancey.kai",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": ["UIColorName": ""],
                "CFBundleDisplayName": "Kai",
            ]),
            sources: ["App/Sources/**"],
            dependencies: [
                .package(product: "KaiCore"),
                .package(product: "KaiFSRS"),
                .package(product: "KaiAI"),
                .package(product: "KaiServices"),
                .package(product: "KaiUI"),
            ]
        ),
        .target(
            name: "KaiTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "app.yancey.kaiTests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["App/Tests/**"],
            dependencies: [
                .target(name: "Kai"),
            ]
        ),
    ]
)
