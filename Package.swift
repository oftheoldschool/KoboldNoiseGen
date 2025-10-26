// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "KoboldNoiseGeneration",
    products: [
        .library(
            name: "KoboldNoiseGeneration",
            targets: [
                "KoboldFractalNoise",
                "KoboldOpenSimplex2",
                "KoboldVoronoi"
            ]
        ),
    ],
    targets: [
        .target(
            name: "KoboldFractalNoise",
            dependencies: [
                "KoboldOpenSimplex2",
                "KoboldVoronoi"
            ],
            path: "./Sources/KoboldFractalNoise",
            resources: [
                .copy("Metal/Shaders")
            ]
        ),
        .target(
            name: "KoboldOpenSimplex2",
            path: "./Sources/KoboldOpenSimplex2",
            resources: [
                .copy("Metal/Shaders")
            ]
        ),
        .target(
            name: "KoboldVoronoi",
            path: "./Sources/KoboldVoronoi",
            resources: [
                .copy("Metal/Shaders")
            ]
        ),
        .testTarget(
            name: "KoboldFractalNoiseTests",
            dependencies: ["KoboldFractalNoise"]
        ),
        .testTarget(
            name: "KoboldOpenSimplex2Tests",
            dependencies: ["KoboldOpenSimplex2"]
        ),
    ]
)
