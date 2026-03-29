// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ScreenTime",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .executable(name: "ScreenTime", targets: ["ScreenTimeApp"]),
        .library(name: "ScreenTimeCore", targets: ["ScreenTimeCore"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ScreenTimeApp",
            dependencies: ["ScreenTimeCore"],
            path: "Sources/App",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .target(
            name: "ScreenTimeCore",
            dependencies: [],
            path: "Sources",
            exclude: ["App"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "ScreenTimeTests",
            dependencies: ["ScreenTimeCore"],
            path: "Tests",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
