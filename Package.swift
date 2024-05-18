// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "SPMNoiseGeneration",
    products: [
        .library(
            name: "SPMNoiseGeneration",
            targets: ["SPMNoiseGeneration"]),
    ],
    dependencies: [
        .package(url: "https://github.com/andystanton/SPMOpenSimplex2.git", "0.0.0"..<"0.1.0")
    ],
    targets: [
        .target(
            name: "SPMNoiseGeneration",
            dependencies: [
                .product(name: "SPMOpenSimplex2", package: "spmopensimplex2")]),
        .testTarget(
            name: "SPMNoiseGenerationTests",
            dependencies: ["SPMNoiseGeneration"]),
    ]
)
