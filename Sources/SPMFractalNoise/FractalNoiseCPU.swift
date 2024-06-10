import SPMOpenSimplex2
import simd

public class FractalNoiseCPU {
    private let openSimplex2: OpenSimplex2CPU

    public init() {
        self.openSimplex2 = OpenSimplex2CPU()
    }

    private func getNoise3Value(
        noiseTypeParameters: FractalNoiseTypeParameters,
        coord: SIMD3<Float>
    ) -> Float {
        switch noiseTypeParameters {
        case .OpenSimplex2(let parameters):
            return openSimplex2.noise3(
                openSimplex2NoiseParameters: parameters,
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
        return fractalNoise
    }
}
