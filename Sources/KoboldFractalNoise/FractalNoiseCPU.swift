import KoboldOpenSimplex2
import KoboldVoronoi
import simd

public class FractalNoiseCPU {
    private let openSimplex2: OpenSimplex2CPU
    private let voronoi: VoronoiCPU

    public init() {
        self.openSimplex2 = OpenSimplex2CPU()
        self.voronoi = VoronoiCPU()
    }

    private func getNoise3Value(
        noiseTypeParameters: FractalNoiseTypeParameters,
        coord: SIMD3<Float>
    ) -> Float {
        switch noiseTypeParameters {
        case .openSimplex2(let parameters):
            return openSimplex2.noise3(
                openSimplex2NoiseParameters: parameters,
                coord: coord)
        case .voronoi(let parameters):
            return voronoi.noise3(
                voronoiNoiseParameters: parameters,
                coord: coord)
        }
    }
}

extension FractalNoiseCPU: FractalNoise {
    public func noise3(
        fractalNoiseParameters: FractalNoiseParameters,
        coords: [SIMD3<Float>]
    ) -> [Float] {
        return coords.map {
            noise3(
                fractalNoiseParameters: fractalNoiseParameters,
                coord: $0)
        }
    }

    public func noise3(
        fractalNoiseParameters: FractalNoiseParameters,
        coord: SIMD3<Float>
    ) -> Float {
        let scaledCoord = coord * fractalNoiseParameters.coordinateScale
        return fbmWithWarp(fractalNoiseParameters: fractalNoiseParameters, coord: scaledCoord)
    }

    private func fbmWithWarp(
        fractalNoiseParameters: FractalNoiseParameters,
        coord: SIMD3<Float>
    ) -> Float {
        var fractalNoise = Float.zero

        for _ in 0..<fractalNoiseParameters.warpIterations {
            fractalNoise = fbmBase(
                fractalNoiseParameters: fractalNoiseParameters,
                coord: coord + fractalNoise * fractalNoiseParameters.warpScale
            )
        }
        
        return fractalNoise
    }
    
    private func fbmBase(
        fractalNoiseParameters: FractalNoiseParameters,
        coord: SIMD3<Float>
    ) -> Float {
        var fractalNoise = Float.zero
        var amplitude = fractalNoiseParameters.startingAmplitude
        var frequency = fractalNoiseParameters.startingFrequency
        let gain = exp2(-fractalNoiseParameters.hurstExponent)

        for _ in 0..<fractalNoiseParameters.octaves {
            fractalNoise += amplitude * getNoise3Value(
                noiseTypeParameters: fractalNoiseParameters.noiseTypeParameters,
                coord: coord * frequency)

            frequency *= fractalNoiseParameters.lacunarity
            amplitude *= gain
        }
        return min(max(fractalNoise, -1.0), 1.0)
    }
}
