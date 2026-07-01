// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Uluru",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "Uluru", targets: ["Uluru"])
    ],
    targets: [
        .target(
            name: "Uluru",
            path: "Sources"
        ),
        .testTarget(
            name: "Tests",
            dependencies: ["Uluru"]
        )
    ]
)
