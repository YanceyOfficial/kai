// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KaiCore",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "KaiCore", targets: ["KaiCore"])
    ],
    targets: [
        .target(name: "KaiCore"),
        .testTarget(name: "KaiCoreTests", dependencies: ["KaiCore"])
    ]
)
