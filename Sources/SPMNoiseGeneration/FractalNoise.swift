import SPMOpenSimplex2

public struct FractalOpenSimplex2NoiseParameters {
    let openSimplex2Variant: OpenSimplex2Noise2Variant
    let openSimplex3Variant: OpenSimplex2Noise3Variant
    let openSimplex4Variant: OpenSimplex2Noise4Variant

    public init(
        openSimplex2Variant: OpenSimplex2Noise2Variant = .standard,
        openSimplex3Variant: OpenSimplex2Noise3Variant = .xy,
        openSimplex4Variant: OpenSimplex2Noise4Variant = .xyz
    ) {
        self.openSimplex2Variant = openSimplex2Variant
        self.openSimplex3Variant = openSimplex3Variant
        self.openSimplex4Variant = openSimplex4Variant
    }
}

public enum FractalNoiseTypeParameters {
    case OpenSimplex2(FractalOpenSimplex2NoiseParameters)
}

public struct FractalNoiseParameters {
    let noiseTypeParameters: FractalNoiseTypeParameters

    let octaves: Int32
    let lacunarity: Float
    let hurstExponent: Float

    let startingAmplitude: Float
    let startingFrequency: Float

    public init(noiseTypeParameters: FractalNoiseTypeParameters, octaves: Int32, lacunarity: Float, hurstExponent: Float, startingAmplitude: Float, startingFrequency: Float) {
        self.noiseTypeParameters = noiseTypeParameters
        self.octaves = octaves
        self.lacunarity = lacunarity
        self.hurstExponent = hurstExponent
        self.startingAmplitude = startingAmplitude
        self.startingFrequency = startingFrequency
    }
}

public protocol FractalNoise {
    func noise3(seed: Int32, coord: SIMD3<Float>, fractalNoiseParameters: FractalNoiseParameters) -> Float
    func noise3(seed: Int32, coords: [SIMD3<Float>], fractalNoiseParameters: FractalNoiseParameters) -> [Float]
}

