import Foundation
import simd
import SPMOpenSimplex2

protocol FractalNoiseMetalNoiseShader {
    static var baseFunction: String { get }
    static var metalFunction: String { get }
    static var functionName: String { get }
}

extension FractalNoiseMetalNoiseShader {
    public static func getFunction() -> String {
        return baseFunction + metalFunction
    }
}

public enum FractalNoiseMetalType: Int8 {
    case OpenSimplex2
}

public enum FractalNoiseMetalTypeParameters {
    case OpenSimplex2(OpenSimplex2MetalParameters)
}


public struct FractalNoiseMetalParameters {
    let lacunarity: Float
    let gain: Float

    let startingAmplitude: Float
    let startingFrequency: Float

    let octaves: Int32
    private let octavesPad: Int32 = 0

    let noiseType: FractalNoiseMetalType
    let noiseTypeParameters: FractalNoiseMetalTypeParameters
}

public struct FractalNoiseOpenSimplex2MetalParameters {
    let seed: Int
    let noise2Variant: OpenSimplex2MetalNoise2Variant
    let noise3Variant: OpenSimplex2MetalNoise3Variant
    let noise4Variant: OpenSimplex2MetalNoise4Variant

    public init(
        seed: Int,
        noise2Variant: OpenSimplex2MetalNoise2Variant = .standard,
        noise3Variant: OpenSimplex2MetalNoise3Variant = .xy,
        noise4Variant: OpenSimplex2MetalNoise4Variant = .xyz
    ) {
        self.seed = seed
        self.noise2Variant = noise2Variant
        self.noise3Variant = noise3Variant
        self.noise4Variant = noise4Variant
    }
}

public class FractalNoiseMetalShaderLoader {
    public let shader: String
    public let functionNames: [String]

    public init(dimensionality: [OpenSimplex2MetalDimensionality]) {
        self.shader = Self.baseShader + dimensionality.map {
            switch $0 {
            case .two: FractalNoiseMetalNoise2.getFunction()
            case .three: FractalNoiseMetalNoise3.getFunction()
            case .four: FractalNoiseMetalNoise4.getFunction()
            }
        }.joined(separator: "\n")
        self.functionNames = dimensionality.map {
            switch $0 {
            case .two: Self.noise2FunctionName
            case .three: Self.noise3FunctionName
            case .four: Self.noise4FunctionName
            }
        }
    }

    public static var noise2FunctionName = FractalNoiseMetalNoise2.functionName
    public static var noise3FunctionName = FractalNoiseMetalNoise3.functionName
    public static var noise4FunctionName = FractalNoiseMetalNoise4.functionName

    private static let baseShader = """
        enum class FractalNoiseMetalType: int8_t {
            openSimplex2 = 0,
        };

        union FractalNoiseMetalTypeParameters {
            OpenSimplex2MetalParameters openSimplex2Parameters;
        };

        struct FractalNoiseMetalParameters {
            float lacunarity;
            float gain;
    
            float startingAmplitude;
            float startingFrequency;

            int octaves;

            FractalNoiseMetalType noiseType;

            FractalNoiseMetalTypeParameters noiseTypeParameters;
        };

    """
}
