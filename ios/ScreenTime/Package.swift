// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScreenTime",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "ScreenTime", targets: ["ScreenTime"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ScreenTime",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "ScreenTimeTests",
            dependencies: ["ScreenTime"],
            path: "Tests"
        )
    ]
)
