// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "SoA",
    products: [
        .library(
            name: "SoA",
            targets: ["SoA"]),
    ],
    dependencies: [
        .package(url: "https://github.com/google/swift-benchmark", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "SoA",
            dependencies: []),
        .executableTarget(
            name: "bench",
            dependencies: [
                .product(name: "Benchmark",package: "swift-benchmark" ),
                "SoA"
            ]
        ),
        .testTarget(
            name: "SoATests",
            dependencies: ["SoA"]),
    ]
)
