# Kobold Noise Generation

A Swift Package containing noise generation functionality.

## Modules

Each noise module comes with two implementations:
1. Swift implementation that runs on the CPU
2. Swift code for generating a Metal Shading Language Kernel that can be run on the GPU

The use case for the second approach is for a Metal project in Swift Playgrounds where Metal shader files can't be used directly but shader code must be provided as a string to load into a MTLLibrary.

### Fractal Noise

Fractional Brownian Motion implementation over a noise function.

### Open Simplex 2

A port of [KdotJPG](https://github.com/KdotJPG)'s [Open Simplex 2](https://github.com/KdotJPG/OpenSimplex2) for Swift/Metal.

## Usage

Define a dependency from the source package to this one ([Swift Package Manager Docs](https://github.com/apple/swift-package-manager/blob/main/Documentation/Usage.md#defining-dependencies)).

To use the CPU implementation you can run:

```swift
import KoboldFractalNoise

...

let fractalNoise = FractalNoiseCPU()


let fractalNoiseParameters = FractalNoiseParameters(
    noiseTypeParameters: .OpenSimplex2(
        OpenSimplex2NoiseParameters(
            seed: 420,
            noise3Variant: .xz)),
    octaves: 8,
    lacunarity: 2,
    hurstExponent: 1,
    startingAmplitude: 1,
    startingFrequency: 0.0025,
    coordinateScale: 0.5,
    warpIterations: 3,
    warpScale: 200)

let noise: Float = openSimplex2.noise3(
    fractalNoiseParameters: fractalNoiseParameters,
    coord: SIMD3<Float>(4.3, 2.0, 1.4))
```

A Metal reference implementation is provided with the same interface as the CPU implementation. To use it, the above code can be changed to use `FractalNoiseMetal()`. However it creates Metal resources which should be managed by the calling app, so direct usage is not recommended, and the implementation should be used instead as an example of how to generate the Metal shader.
