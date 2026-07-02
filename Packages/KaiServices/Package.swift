// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KaiServices",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "KaiServices", targets: ["KaiServices"])
    ],
    dependencies: [
        .package(path: "../KaiFSRS")
    ],
    targets: [
        .target(name: "KaiServices", dependencies: ["KaiFSRS"]),
        .testTarget(name: "KaiServicesTests", dependencies: ["KaiServices"])
    ]
)
