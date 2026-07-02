// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KaiUI",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "KaiUI", targets: ["KaiUI"])
    ],
    targets: [
        .target(name: "KaiUI"),
        .testTarget(name: "KaiUITests", dependencies: ["KaiUI"])
    ]
)
