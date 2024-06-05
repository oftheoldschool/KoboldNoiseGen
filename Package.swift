// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "SPMNoiseGeneration",
    products: [
        .library(
            name: "SPMNoiseGeneration",
            targets: ["SPMFractalNoise", "SPMOpenSimplex2"]),
    ],
    targets: [
        .target(
            name: "SPMFractalNoise",
            dependencies: ["SPMOpenSimplex2"]),
        .target(
            name: "SPMOpenSimplex2"),
        .testTarget(
            name: "SPMFractalNoiseTests",
            dependencies: ["SPMFractalNoise"]),
        .testTarget(
            name: "SPMOpenSimplex2Tests",
            dependencies: ["SPMOpenSimplex2"]),
    ]
)
