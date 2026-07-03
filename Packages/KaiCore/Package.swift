// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KaiCore",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "KaiCore", targets: ["KaiCore"])
    ],
    dependencies: [
        .package(path: "../KaiFSRS")
    ],
    targets: [
        .target(name: "KaiCore", dependencies: ["KaiFSRS"]),
        .testTarget(name: "KaiCoreTests", dependencies: ["KaiCore"])
    ]
)
