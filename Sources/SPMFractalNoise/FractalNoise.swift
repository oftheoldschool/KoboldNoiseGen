@_exported import SPMOpenSimplex2

public enum FractalNoiseTypeParameters {
    case OpenSimplex2(OpenSimplex2NoiseParameters)
}

public struct FractalNoiseParameters {
    let noiseTypeParameters: FractalNoiseTypeParameters

    let octaves: Int32
    let lacunarity: Float
    let hurstExponent: Float

    let startingAmplitude: Float
    let startingFrequency: Float

    public init(
        noiseTypeParameters: FractalNoiseTypeParameters,
        octaves: Int32,
        lacunarity: Float,
        hurstExponent: Float,
        startingAmplitude: Float,
        startingFrequency: Float
    ) {
        self.noiseTypeParameters = noiseTypeParameters
        self.octaves = octaves
        self.lacunarity = lacunarity
        self.hurstExponent = hurstExponent
        self.startingAmplitude = startingAmplitude
        self.startingFrequency = startingFrequency
    }
}

public protocol FractalNoise {
    func noise3(
        fractalNoiseParameters: FractalNoiseParameters,
        coord: SIMD3<Float>
    ) -> Float

    func noise3(
        fractalNoiseParameters: FractalNoiseParameters,
        coords: [SIMD3<Float>]
    ) -> [Float]
}

