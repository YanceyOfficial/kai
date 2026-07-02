// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KaiAI",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "KaiAI", targets: ["KaiAI"])
    ],
    dependencies: [
        .package(path: "../KaiCore")
    ],
    targets: [
        .target(name: "KaiAI", dependencies: ["KaiCore"]),
        .testTarget(name: "KaiAITests", dependencies: ["KaiAI"])
    ]
)
