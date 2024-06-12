public enum OpenSimplex2Noise2Variant {
    case standard
    case x
}

public enum OpenSimplex2Noise3Variant {
    case xy
    case xz
    case fallback
}

public enum OpenSimplex2Noise4Variant {
    case xyz
    case xyz_xy
    case xyz_xz
    case xy_zw
    case fallback
}

public struct OpenSimplex2NoiseParameters {
    public var seed: Int32
    public var noise2Variant: OpenSimplex2Noise2Variant
    public var noise3Variant: OpenSimplex2Noise3Variant
    public var noise4Variant: OpenSimplex2Noise4Variant

    public init(
        seed: Int32 = 0,
        noise2Variant: OpenSimplex2Noise2Variant = .standard,
        noise3Variant: OpenSimplex2Noise3Variant = .xy,
        noise4Variant: OpenSimplex2Noise4Variant = .xyz
    ) {
        self.seed = seed
        self.noise2Variant = noise2Variant
        self.noise3Variant = noise3Variant
        self.noise4Variant = noise4Variant
    }
}

public protocol OpenSimplex2 {
    func noise2(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coord: SIMD2<Float>) -> Float
    func noise3(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coord: SIMD3<Float>) -> Float
    func noise4(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coord: SIMD4<Float>) -> Float

    func noise2(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coord: SIMD2<Double>) -> Float
    func noise3(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coord: SIMD3<Double>) -> Float
    func noise4(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coord: SIMD4<Double>) -> Float

    func noise2(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coords: [SIMD2<Float>]) -> [Float]
    func noise3(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coords: [SIMD3<Float>]) -> [Float]
    func noise4(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coords: [SIMD4<Float>]) -> [Float]

    func noise2(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coords: [SIMD2<Double>]) -> [Float]
    func noise3(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coords: [SIMD3<Double>]) -> [Float]
    func noise4(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coords: [SIMD4<Double>]) -> [Float]
}

public extension OpenSimplex2 {
    func noise2(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coord: SIMD2<Float>) -> Float {
        return noise2(openSimplex2NoiseParameters: openSimplex2NoiseParameters, coord: SIMD2<Double>(coord))
    }

    func noise3(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coord: SIMD3<Float>) -> Float {
        return noise3(openSimplex2NoiseParameters: openSimplex2NoiseParameters, coord: SIMD3<Double>(coord))
    }

    func noise4(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coord: SIMD4<Float>) -> Float {
        return noise4(openSimplex2NoiseParameters: openSimplex2NoiseParameters, coord: SIMD4<Double>(coord))
    }

    func noise2(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coords: [SIMD2<Float>]) -> [Float] {
        return noise2(openSimplex2NoiseParameters: openSimplex2NoiseParameters, coords: coords.map(SIMD2<Double>.init))
    }

    func noise3(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coords: [SIMD3<Float>]) -> [Float] {
        return noise3(openSimplex2NoiseParameters: openSimplex2NoiseParameters, coords: coords.map(SIMD3<Double>.init))
    }

    func noise4(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coords: [SIMD4<Float>]) -> [Float] {
        return noise4(openSimplex2NoiseParameters: openSimplex2NoiseParameters, coords: coords.map(SIMD4<Double>.init))
    }
}
