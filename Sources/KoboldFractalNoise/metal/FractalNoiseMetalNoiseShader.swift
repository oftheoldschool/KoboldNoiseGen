import Foundation
import simd
import KoboldOpenSimplex2

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
    public let lacunarity: Float
    public let gain: Float

    public let startingAmplitude: Float
    public let startingFrequency: Float

    public let octaves: Int32
    public let warpIterations: Int32

    public let warpScale: Float
    public let coordinateScale: Float

    private let pad0: Float = 0

    let noiseType: FractalNoiseMetalType
    let noiseTypeParameters: FractalNoiseMetalTypeParameters
}

public extension FractalNoiseMetalParameters {
    init(fractalNoiseParameters: FractalNoiseParameters) {
        self.lacunarity = fractalNoiseParameters.lacunarity
        self.gain = exp2(-fractalNoiseParameters.hurstExponent)
        self.startingAmplitude = fractalNoiseParameters.startingAmplitude
        self.startingFrequency = fractalNoiseParameters.startingFrequency
        self.octaves = fractalNoiseParameters.octaves
        self.coordinateScale = fractalNoiseParameters.coordinateScale
        self.warpIterations = fractalNoiseParameters.warpIterations
        self.warpScale = fractalNoiseParameters.warpScale
        switch fractalNoiseParameters.noiseTypeParameters {
        case .OpenSimplex2(let openSimplexParams):
            self.noiseType = .OpenSimplex2
            self.noiseTypeParameters = .OpenSimplex2(openSimplexParams.toMetal())
        }
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
        #ifndef FNOISE_REP1
        #define FNOISE_REP1(FN, ...) FN(0, ##__VA_ARGS__)
        #endif
        #ifndef FNOISE_REP2
        #define FNOISE_REP2(FN, ...) FNOISE_REP1(FN, ##__VA_ARGS__) FN(1, ##__VA_ARGS__)
        #endif
        #ifndef FNOISE_REP3
        #define FNOISE_REP3(FN, ...) FNOISE_REP2(FN, ##__VA_ARGS__) FN(2, ##__VA_ARGS__)
        #endif
        #ifndef FNOISE_REP4
        #define FNOISE_REP4(FN, ...) FNOISE_REP3(FN, ##__VA_ARGS__) FN(3, ##__VA_ARGS__)
        #endif
        #ifndef FNOISE_REP5
        #define FNOISE_REP5(FN, ...) FNOISE_REP4(FN, ##__VA_ARGS__) FN(4, ##__VA_ARGS__)
        #endif
        #ifndef FNOISE_REP6
        #define FNOISE_REP6(FN, ...) FNOISE_REP5(FN, ##__VA_ARGS__) FN(5, ##__VA_ARGS__)
        #endif
        #ifndef FNOISE_REP7
        #define FNOISE_REP7(FN, ...) FNOISE_REP6(FN, ##__VA_ARGS__) FN(6, ##__VA_ARGS__)
        #endif
        #ifndef FNOISE_REP8
        #define FNOISE_REP8(FN, ...) FNOISE_REP7(FN, ##__VA_ARGS__) FN(7, ##__VA_ARGS__)
        #endif
        #ifndef FNOISE_REP9
        #define FNOISE_REP9(FN, ...) FNOISE_REP8(FN, ##__VA_ARGS__) FN(8, ##__VA_ARGS__)
        #endif
        #ifndef FNOISE_REP10
        #define FNOISE_REP10(FN, ...) FNOISE_REP9(FN, ##__VA_ARGS__) FN(9, ##__VA_ARGS__)
        #endif
        #ifndef FNOISE_REP11
        #define FNOISE_REP11(FN, ...) FNOISE_REP10(FN, ##__VA_ARGS__) FN(10, ##__VA_ARGS__)
        #endif
        #ifndef FNOISE_REP12
        #define FNOISE_REP12(FN, ...) FNOISE_REP11(FN, ##__VA_ARGS__) FN(11, ##__VA_ARGS__)
        #endif
        #ifndef FNOISE_REP13
        #define FNOISE_REP13(FN, ...) FNOISE_REP12(FN, ##__VA_ARGS__) FN(12, ##__VA_ARGS__)
        #endif
        #ifndef FNOISE_REP14
        #define FNOISE_REP14(FN, ...) FNOISE_REP13(FN, ##__VA_ARGS__) FN(13, ##__VA_ARGS__)
        #endif
        #ifndef FNOISE_REP15
        #define FNOISE_REP15(FN, ...) FNOISE_REP14(FN, ##__VA_ARGS__) FN(14, ##__VA_ARGS__)
        #endif
        #ifndef FNOISE_REP16
        #define FNOISE_REP16(FN, ...) FNOISE_REP15(FN, ##__VA_ARGS__) FN(15, ##__VA_ARGS__)
        #endif
        #ifndef FNOISE_REPEAT
        #define FNOISE_REPEAT(N, ...) FNOISE_REP ## N(__VA_ARGS__)
        #endif

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
            int warpIterations;

            float warpScale;
            float coordinateScale;

            FractalNoiseMetalType noiseType;

            FractalNoiseMetalTypeParameters noiseTypeParameters;
        };

    """
}
