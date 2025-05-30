// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "HalfSheet",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "HalfSheet",
            targets: ["HalfSheet"]
        )
    ],
    targets: [
        .target(
            name: "HalfSheet",
            path: "Sources/HalfSheet"
        ),
        .testTarget(
            name: "HalfSheetTests",
            dependencies: ["HalfSheet"],
            path: "Tests/HalfSheetTests"
        )
    ]
)
