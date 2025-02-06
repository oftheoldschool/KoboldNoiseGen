// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "KoboldNoiseGeneration",
    products: [
        .library(
            name: "KoboldNoiseGeneration",
            targets: ["KoboldFractalNoise", "KoboldOpenSimplex2"]),
    ],
    targets: [
        .target(
            name: "KoboldFractalNoise",
            dependencies: ["KoboldOpenSimplex2"]),
        .target(
            name: "KoboldOpenSimplex2"),
        .testTarget(
            name: "KoboldFractalNoiseTests",
            dependencies: ["KoboldFractalNoise"]),
        .testTarget(
            name: "KoboldOpenSimplex2Tests",
            dependencies: ["KoboldOpenSimplex2"]),
    ]
)
