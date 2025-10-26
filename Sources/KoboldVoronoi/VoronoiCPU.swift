import Foundation
import simd

public class VoronoiCPU {
    private static let PRIME_X: UInt64 = 0x5205402B9270C86F
    private static let PRIME_Y: UInt64 = 0x598CD327003817B5
    private static let PRIME_Z: UInt64 = 0x5BCC226E9FA0BACB
    private static let PRIME_W: UInt64 = 0x56CC5227E58F554B
    private static let HASH_MULTIPLIER: UInt64 = 0x53A3F72DEEC546F5

    public init() {}

    private func hash2D(seed: Int32, xPrimed: Int64, yPrimed: Int64) -> UInt64 {
        var hash = UInt64(truncatingIfNeeded: seed) ^ UInt64(truncatingIfNeeded: xPrimed) ^ UInt64(truncatingIfNeeded: yPrimed)
        hash = hash &* Self.HASH_MULTIPLIER
        hash = hash ^ (hash >> 32)
        return hash
    }

    private func hash3D(seed: Int32, xPrimed: Int64, yPrimed: Int64, zPrimed: Int64) -> UInt64 {
        var hash = UInt64(truncatingIfNeeded: seed) ^ UInt64(truncatingIfNeeded: xPrimed) ^ UInt64(truncatingIfNeeded: yPrimed) ^ UInt64(truncatingIfNeeded: zPrimed)
        hash = hash &* Self.HASH_MULTIPLIER
        hash = hash ^ (hash >> 32)
        return hash
    }

    private func hash4D(seed: Int32, xPrimed: Int64, yPrimed: Int64, zPrimed: Int64, wPrimed: Int64) -> UInt64 {
        var hash = UInt64(truncatingIfNeeded: seed) ^ UInt64(truncatingIfNeeded: xPrimed) ^ UInt64(truncatingIfNeeded: yPrimed) ^ UInt64(truncatingIfNeeded: zPrimed) ^ UInt64(truncatingIfNeeded: wPrimed)
        hash = hash &* Self.HASH_MULTIPLIER
        hash = hash ^ (hash >> 32)
        return hash
    }

    private func hashToFloat(hash: UInt64) -> Float {
        return Float(hash & 0xFFFFFF) / Float(0xFFFFFF)
    }

    private func fastFloor(_ x: Double) -> Int32 {
        let xi = Int32(x)
        return x < Double(xi) ? xi - 1 : xi
    }

    private func calculateDistance(
        _ distanceFunction: VoronoiDistanceFunction,
        _ dx: Float, _ dy: Float, _ dz: Float = 0, _ dw: Float = 0
    ) -> Float {
        switch distanceFunction {
        case .euclidean:
            if dw != 0 {
                return sqrt(dx*dx + dy*dy + dz*dz + dw*dw)
            } else if dz != 0 {
                return sqrt(dx*dx + dy*dy + dz*dz)
            } else {
                return sqrt(dx*dx + dy*dy)
            }
        case .manhattan:
            if dw != 0 {
                return abs(dx) + abs(dy) + abs(dz) + abs(dw)
            } else if dz != 0 {
                return abs(dx) + abs(dy) + abs(dz)
            } else {
                return abs(dx) + abs(dy)
            }
        case .chebyshev:
            if dw != 0 {
                return max(abs(dx), abs(dy), abs(dz), abs(dw))
            } else if dz != 0 {
                return max(abs(dx), abs(dy), abs(dz))
            } else {
                return max(abs(dx), abs(dy))
            }
        case .minkowski(let p):
            if dw != 0 {
                return pow(pow(abs(dx), p) + pow(abs(dy), p) + pow(abs(dz), p) + pow(abs(dw), p), 1.0/p)
            } else if dz != 0 {
                return pow(pow(abs(dx), p) + pow(abs(dy), p) + pow(abs(dz), p), 1.0/p)
            } else {
                return pow(pow(abs(dx), p) + pow(abs(dy), p), 1.0/p)
            }
        }
    }

    private func voronoi2D(
        seed: Int32,
        x: Double,
        y: Double,
        distanceFunction: VoronoiDistanceFunction,
        returnType: VoronoiReturnType,
        jitter: Float
    ) -> Float {
        let xr = fastFloor(x)
        let yr = fastFloor(y)

        var distance1 = Float.greatestFiniteMagnitude
        var distance2 = Float.greatestFiniteMagnitude
        var closestHash: UInt64 = 0

        for xi in (xr-1)...(xr+1) {
            for yi in (yr-1)...(yr+1) {
                let hash = hash2D(seed: seed, 
                                xPrimed: Int64(xi) &* Int64(truncatingIfNeeded: Self.PRIME_X),
                                yPrimed: Int64(yi) &* Int64(truncatingIfNeeded: Self.PRIME_Y))
                
                let vecX = Float(xi) + jitter * (hashToFloat(hash: hash) - 0.5) * 2.0
                let vecY = Float(yi) + jitter * (hashToFloat(hash: hash >> 16) - 0.5) * 2.0

                let distance = calculateDistance(distanceFunction, 
                                               Float(x) - vecX, 
                                               Float(y) - vecY)

                if distance < distance1 {
                    distance2 = distance1
                    distance1 = distance
                    closestHash = hash
                } else if distance < distance2 {
                    distance2 = distance
                }
            }
        }

        switch returnType {
        case .distance:
            return distance1
        case .cellValue:
            return hashToFloat(hash: closestHash)
        case .distance2:
            return distance2
        case .distance2MinusDistance1:
            return distance2 - distance1
        }
    }

    private func voronoi3D(
        seed: Int32,
        x: Double,
        y: Double,
        z: Double,
        distanceFunction: VoronoiDistanceFunction,
        returnType: VoronoiReturnType,
        jitter: Float
    ) -> Float {
        let xr = fastFloor(x)
        let yr = fastFloor(y)
        let zr = fastFloor(z)

        var distance1 = Float.greatestFiniteMagnitude
        var distance2 = Float.greatestFiniteMagnitude
        var closestHash: UInt64 = 0

        for xi in (xr-1)...(xr+1) {
            for yi in (yr-1)...(yr+1) {
                for zi in (zr-1)...(zr+1) {
                    let hash = hash3D(seed: seed,
                                    xPrimed: Int64(xi) &* Int64(truncatingIfNeeded: Self.PRIME_X),
                                    yPrimed: Int64(yi) &* Int64(truncatingIfNeeded: Self.PRIME_Y),
                                    zPrimed: Int64(zi) &* Int64(truncatingIfNeeded: Self.PRIME_Z))
                    
                    let vecX = Float(xi) + jitter * (hashToFloat(hash: hash) - 0.5) * 2.0
                    let vecY = Float(yi) + jitter * (hashToFloat(hash: hash >> 16) - 0.5) * 2.0
                    let vecZ = Float(zi) + jitter * (hashToFloat(hash: hash >> 32) - 0.5) * 2.0

                    let distance = calculateDistance(distanceFunction,
                                                   Float(x) - vecX,
                                                   Float(y) - vecY,
                                                   Float(z) - vecZ)

                    if distance < distance1 {
                        distance2 = distance1
                        distance1 = distance
                        closestHash = hash
                    } else if distance < distance2 {
                        distance2 = distance
                    }
                }
            }
        }

        switch returnType {
        case .distance:
            return distance1
        case .cellValue:
            return hashToFloat(hash: closestHash)
        case .distance2:
            return distance2
        case .distance2MinusDistance1:
            return distance2 - distance1
        }
    }

    private func voronoi4D(
        seed: Int32,
        x: Double,
        y: Double,
        z: Double,
        w: Double,
        distanceFunction: VoronoiDistanceFunction,
        returnType: VoronoiReturnType,
        jitter: Float
    ) -> Float {
        let xr = fastFloor(x)
        let yr = fastFloor(y)
        let zr = fastFloor(z)
        let wr = fastFloor(w)

        var distance1 = Float.greatestFiniteMagnitude
        var distance2 = Float.greatestFiniteMagnitude
        var closestHash: UInt64 = 0

        for xi in (xr-1)...(xr+1) {
            for yi in (yr-1)...(yr+1) {
                for zi in (zr-1)...(zr+1) {
                    for wi in (wr-1)...(wr+1) {
                        let hash = hash4D(seed: seed,
                                        xPrimed: Int64(xi) &* Int64(truncatingIfNeeded: Self.PRIME_X),
                                        yPrimed: Int64(yi) &* Int64(truncatingIfNeeded: Self.PRIME_Y),
                                        zPrimed: Int64(zi) &* Int64(truncatingIfNeeded: Self.PRIME_Z),
                                        wPrimed: Int64(wi) &* Int64(truncatingIfNeeded: Self.PRIME_W))
                        
                        let vecX = Float(xi) + jitter * (hashToFloat(hash: hash) - 0.5) * 2.0
                        let vecY = Float(yi) + jitter * (hashToFloat(hash: hash >> 16) - 0.5) * 2.0
                        let vecZ = Float(zi) + jitter * (hashToFloat(hash: hash >> 32) - 0.5) * 2.0
                        let vecW = Float(wi) + jitter * (hashToFloat(hash: hash >> 48) - 0.5) * 2.0

                        let distance = calculateDistance(distanceFunction,
                                                       Float(x) - vecX,
                                                       Float(y) - vecY,
                                                       Float(z) - vecZ,
                                                       Float(w) - vecW)

                        if distance < distance1 {
                            distance2 = distance1
                            distance1 = distance
                            closestHash = hash
                        } else if distance < distance2 {
                            distance2 = distance
                        }
                    }
                }
            }
        }

        switch returnType {
        case .distance:
            return distance1
        case .cellValue:
            return hashToFloat(hash: closestHash)
        case .distance2:
            return distance2
        case .distance2MinusDistance1:
            return distance2 - distance1
        }
    }
}

extension VoronoiCPU: Voronoi {
    public func noise2(voronoiNoiseParameters: VoronoiNoiseParameters, coord: SIMD2<Double>) -> Float {
        return voronoi2D(
            seed: voronoiNoiseParameters.seed,
            x: coord.x,
            y: coord.y,
            distanceFunction: voronoiNoiseParameters.distanceFunction,
            returnType: voronoiNoiseParameters.returnType,
            jitter: voronoiNoiseParameters.jitter
        )
    }

    public func noise2(voronoiNoiseParameters: VoronoiNoiseParameters, coords: [SIMD2<Double>]) -> [Float] {
        return coords.map { coord in
            voronoi2D(
                seed: voronoiNoiseParameters.seed,
                x: coord.x,
                y: coord.y,
                distanceFunction: voronoiNoiseParameters.distanceFunction,
                returnType: voronoiNoiseParameters.returnType,
                jitter: voronoiNoiseParameters.jitter
            )
        }
    }

    public func noise3(voronoiNoiseParameters: VoronoiNoiseParameters, coord: SIMD3<Double>) -> Float {
        return voronoi3D(
            seed: voronoiNoiseParameters.seed,
            x: coord.x,
            y: coord.y,
            z: coord.z,
            distanceFunction: voronoiNoiseParameters.distanceFunction,
            returnType: voronoiNoiseParameters.returnType,
            jitter: voronoiNoiseParameters.jitter
        )
    }

    public func noise3(voronoiNoiseParameters: VoronoiNoiseParameters, coords: [SIMD3<Double>]) -> [Float] {
        return coords.map { coord in
            voronoi3D(
                seed: voronoiNoiseParameters.seed,
                x: coord.x,
                y: coord.y,
                z: coord.z,
                distanceFunction: voronoiNoiseParameters.distanceFunction,
                returnType: voronoiNoiseParameters.returnType,
                jitter: voronoiNoiseParameters.jitter
            )
        }
    }

    public func noise4(voronoiNoiseParameters: VoronoiNoiseParameters, coord: SIMD4<Double>) -> Float {
        return voronoi4D(
            seed: voronoiNoiseParameters.seed,
            x: coord.x,
            y: coord.y,
            z: coord.z,
            w: coord.w,
            distanceFunction: voronoiNoiseParameters.distanceFunction,
            returnType: voronoiNoiseParameters.returnType,
            jitter: voronoiNoiseParameters.jitter
        )
    }

    public func noise4(voronoiNoiseParameters: VoronoiNoiseParameters, coords: [SIMD4<Double>]) -> [Float] {
        return coords.map { coord in
            voronoi4D(
                seed: voronoiNoiseParameters.seed,
                x: coord.x,
                y: coord.y,
                z: coord.z,
                w: coord.w,
                distanceFunction: voronoiNoiseParameters.distanceFunction,
                returnType: voronoiNoiseParameters.returnType,
                jitter: voronoiNoiseParameters.jitter
            )
        }
    }
}
