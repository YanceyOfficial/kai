// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KaiFSRS",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "KaiFSRS", targets: ["KaiFSRS"])
    ],
    targets: [
        .target(name: "KaiFSRS"),
        .testTarget(name: "KaiFSRSTests", dependencies: ["KaiFSRS"])
    ]
)
