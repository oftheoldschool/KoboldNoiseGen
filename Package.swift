// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "SPMNoiseGeneration",
    products: [
        .library(
            name: "SPMNoiseGeneration",
            targets: ["SPMNoiseGeneration"]),
    ],
    targets: [
        .target(
            name: "SPMNoiseGeneration",
            dependencies: ["SPMOpenSimplex2"]),
        .target(
            name: "SPMOpenSimplex2"),
        .testTarget(
            name: "SPMNoiseGenerationTests",
            dependencies: ["SPMNoiseGeneration"]),
        .testTarget(
            name: "SPMOpenSimplex2Tests",
            dependencies: ["SPMOpenSimplex2"]),
    ]
)
