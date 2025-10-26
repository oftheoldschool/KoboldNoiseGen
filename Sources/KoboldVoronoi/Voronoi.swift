public enum VoronoiDistanceFunction: Hashable {
    case euclidean
    case manhattan
    case chebyshev
    case minkowski(Float)
}

public enum VoronoiReturnType {
    case distance
    case cellValue
    case distance2
    case distance2MinusDistance1
}

public struct VoronoiNoiseParameters {
    public var seed: Int32
    public var distanceFunction: VoronoiDistanceFunction
    public var returnType: VoronoiReturnType
    public var jitter: Float

    public init(
        seed: Int32 = 0,
        distanceFunction: VoronoiDistanceFunction = .euclidean,
        returnType: VoronoiReturnType = .distance,
        jitter: Float = 1.0
    ) {
        self.seed = seed
        self.distanceFunction = distanceFunction
        self.returnType = returnType
        self.jitter = jitter
    }
}

public protocol Voronoi {
    func noise2(voronoiNoiseParameters: VoronoiNoiseParameters, coord: SIMD2<Float>) -> Float
    func noise3(voronoiNoiseParameters: VoronoiNoiseParameters, coord: SIMD3<Float>) -> Float
    func noise4(voronoiNoiseParameters: VoronoiNoiseParameters, coord: SIMD4<Float>) -> Float

    func noise2(voronoiNoiseParameters: VoronoiNoiseParameters, coord: SIMD2<Double>) -> Float
    func noise3(voronoiNoiseParameters: VoronoiNoiseParameters, coord: SIMD3<Double>) -> Float
    func noise4(voronoiNoiseParameters: VoronoiNoiseParameters, coord: SIMD4<Double>) -> Float

    func noise2(voronoiNoiseParameters: VoronoiNoiseParameters, coords: [SIMD2<Float>]) -> [Float]
    func noise3(voronoiNoiseParameters: VoronoiNoiseParameters, coords: [SIMD3<Float>]) -> [Float]
    func noise4(voronoiNoiseParameters: VoronoiNoiseParameters, coords: [SIMD4<Float>]) -> [Float]

    func noise2(voronoiNoiseParameters: VoronoiNoiseParameters, coords: [SIMD2<Double>]) -> [Float]
    func noise3(voronoiNoiseParameters: VoronoiNoiseParameters, coords: [SIMD3<Double>]) -> [Float]
    func noise4(voronoiNoiseParameters: VoronoiNoiseParameters, coords: [SIMD4<Double>]) -> [Float]
}

public extension Voronoi {
    func noise2(voronoiNoiseParameters: VoronoiNoiseParameters, coord: SIMD2<Float>) -> Float {
        return noise2(voronoiNoiseParameters: voronoiNoiseParameters, coord: SIMD2<Double>(coord))
    }

    func noise3(voronoiNoiseParameters: VoronoiNoiseParameters, coord: SIMD3<Float>) -> Float {
        return noise3(voronoiNoiseParameters: voronoiNoiseParameters, coord: SIMD3<Double>(coord))
    }

    func noise4(voronoiNoiseParameters: VoronoiNoiseParameters, coord: SIMD4<Float>) -> Float {
        return noise4(voronoiNoiseParameters: voronoiNoiseParameters, coord: SIMD4<Double>(coord))
    }

    func noise2(voronoiNoiseParameters: VoronoiNoiseParameters, coords: [SIMD2<Float>]) -> [Float] {
        return noise2(voronoiNoiseParameters: voronoiNoiseParameters, coords: coords.map(SIMD2<Double>.init))
    }

    func noise3(voronoiNoiseParameters: VoronoiNoiseParameters, coords: [SIMD3<Float>]) -> [Float] {
        return noise3(voronoiNoiseParameters: voronoiNoiseParameters, coords: coords.map(SIMD3<Double>.init))
    }

    func noise4(voronoiNoiseParameters: VoronoiNoiseParameters, coords: [SIMD4<Float>]) -> [Float] {
        return noise4(voronoiNoiseParameters: voronoiNoiseParameters, coords: coords.map(SIMD4<Double>.init))
    }
}
