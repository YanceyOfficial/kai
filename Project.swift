import ProjectDescription

let project = Project(
    name: "kai-ios",
    packages: [
        .local(path: "Packages/KaiCore"),
        .local(path: "Packages/KaiFSRS"),
        .local(path: "Packages/KaiAI"),
        .local(path: "Packages/KaiServices"),
        .local(path: "Packages/KaiUI"),
    ],
    settings: .settings(base: ["SWIFT_VERSION": "6.0"]),
    targets: [
        .target(
            name: "kai-ios",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tuist.kai-ios",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "CFBundleDisplayName": "Kai",
                    "NSCameraUsageDescription": "Take a photo of text to scan words into your deck.",
                ]
            ),
            buildableFolders: [
                "kai-ios/Sources",
                "kai-ios/Resources",
            ],
            dependencies: [
                .package(product: "KaiCore"),
                .package(product: "KaiFSRS"),
                .package(product: "KaiAI"),
                .package(product: "KaiServices"),
                .package(product: "KaiUI"),
            ]
        ),
        .target(
            name: "kai-iosTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.kai-iosTests",
            infoPlist: .default,
            buildableFolders: [
                "kai-ios/Tests"
            ],
            dependencies: [.target(name: "kai-ios")]
        ),
    ]
)
