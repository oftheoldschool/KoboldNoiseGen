import SPMOpenSimplex2
import simd

public class FractalNoiseCPU {
    private let openSimplex2: OpenSimplex2CPU

    public init() {
        self.openSimplex2 = OpenSimplex2CPU()
    }

    private func getNoise3Value(
        seed: Int32,
        coord: SIMD3<Float>,
        noiseType: FractalNoiseTypeParameters
    ) -> Float {
        switch noiseType {
        case .OpenSimplex2(let parameters):
            return openSimplex2.noise3(
                seed: seed,
                coord: coord,
                variant: parameters.openSimplex3Variant)
        }
    }
}

extension FractalNoiseCPU: FractalNoise {
    public func noise3(
        seed: Int32,
        coords: [SIMD3<Float>],
        fractalNoiseParameters: FractalNoiseParameters
    ) -> [Float] {
        return coords.map {
            noise3(
                seed: seed,
                coord: $0,
                fractalNoiseParameters: fractalNoiseParameters)
        }
    }

    public func noise3(
        seed: Int32,
        coord: SIMD3<Float>,
        fractalNoiseParameters: FractalNoiseParameters
    ) -> Float {
        var fractalNoise = Float.zero
        var amplitude = fractalNoiseParameters.startingAmplitude
        var frequency = fractalNoiseParameters.startingFrequency
        let gain = exp2(-fractalNoiseParameters.hurstExponent)

        for _ in 0..<fractalNoiseParameters.octaves {
            fractalNoise += amplitude * getNoise3Value(
                seed: seed,
                coord: coord * frequency,
                noiseType: fractalNoiseParameters.noiseTypeParameters)

            frequency *= fractalNoiseParameters.lacunarity
            amplitude *= gain
        }
        return fractalNoise
    }
}
