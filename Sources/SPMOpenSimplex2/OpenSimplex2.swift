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

public protocol OpenSimplex2 {
    func noise2(seed: Int32, coord: SIMD2<Float>, variant: OpenSimplex2Noise2Variant) -> Float
    func noise3(seed: Int32, coord: SIMD3<Float>, variant: OpenSimplex2Noise3Variant) -> Float
    func noise4(seed: Int32, coord: SIMD4<Float>, variant: OpenSimplex2Noise4Variant) -> Float

    func noise2(seed: Int32, coord: SIMD2<Double>, variant: OpenSimplex2Noise2Variant) -> Float
    func noise3(seed: Int32, coord: SIMD3<Double>, variant: OpenSimplex2Noise3Variant) -> Float
    func noise4(seed: Int32, coord: SIMD4<Double>, variant: OpenSimplex2Noise4Variant) -> Float

    func noise2(seed: Int32, coords: [SIMD2<Float>], variant: OpenSimplex2Noise2Variant) -> [Float]
    func noise3(seed: Int32, coords: [SIMD3<Float>], variant: OpenSimplex2Noise3Variant) -> [Float]
    func noise4(seed: Int32, coords: [SIMD4<Float>], variant: OpenSimplex2Noise4Variant) -> [Float]

    func noise2(seed: Int32, coords: [SIMD2<Double>], variant: OpenSimplex2Noise2Variant) -> [Float]
    func noise3(seed: Int32, coords: [SIMD3<Double>], variant: OpenSimplex2Noise3Variant) -> [Float]
    func noise4(seed: Int32, coords: [SIMD4<Double>], variant: OpenSimplex2Noise4Variant) -> [Float]
}

public extension OpenSimplex2 {
    func noise2(seed: Int32, coord: SIMD2<Float>, variant: OpenSimplex2Noise2Variant) -> Float {
        return noise2(seed: seed, coord: SIMD2<Double>(coord), variant: variant)
    }

    func noise3(seed: Int32, coord: SIMD3<Float>, variant: OpenSimplex2Noise3Variant) -> Float {
        return noise3(seed: seed, coord: SIMD3<Double>(coord), variant: variant)
    }

    func noise4(seed: Int32, coord: SIMD4<Float>, variant: OpenSimplex2Noise4Variant) -> Float {
        return noise4(seed: seed, coord: SIMD4<Double>(coord), variant: variant)
    }

    func noise2(seed: Int32, coords: [SIMD2<Float>], variant: OpenSimplex2Noise2Variant) -> [Float] {
        return noise2(seed: seed, coords: coords.map(SIMD2<Double>.init), variant: variant)
    }

    func noise3(seed: Int32, coords: [SIMD3<Float>], variant: OpenSimplex2Noise3Variant) -> [Float] {
        return noise3(seed: seed, coords: coords.map(SIMD3<Double>.init), variant: variant)
    }

    func noise4(seed: Int32, coords: [SIMD4<Float>], variant: OpenSimplex2Noise4Variant) -> [Float] {
        return noise4(seed: seed, coords: coords.map(SIMD4<Double>.init), variant: variant)
    }
}
