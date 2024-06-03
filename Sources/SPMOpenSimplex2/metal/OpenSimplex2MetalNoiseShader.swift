import Foundation
import simd

protocol OpenSimplex2MetalNoiseShader {
    static var baseFunction: String { get }
    static var metalFunction: String { get }
    static var functionName: String { get }

    static func getFunction() -> String
    static func getVariableMap() -> [String: String]
}

extension OpenSimplex2MetalNoiseShader {
    public static func getFunction() -> String {
        return getVariableMap().reduce(baseFunction) { (acc, next) in
            acc.replacingOccurrences(of: "${\(next.key)}", with: next.value)
        } + metalFunction
    }

    static func formatDouble(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 12

        let number = NSNumber(value: value)
        return formatter.string(from: number)!
    }
}

public enum OpenSimplex2MetalDimensionality {
    case two
    case three
    case four
}

public enum OpenSimplex2MetalNoise2Variant: Int8 {
    case standard
    case x
}

public enum OpenSimplex2MetalNoise3Variant: Int8 {
    case xy
    case xz
    case fallback
}

public enum OpenSimplex2MetalNoise4Variant: Int8 {
    case xyz
    case xyz_xy
    case xyz_xz
    case xy_zw
    case fallback
}

public struct OpenSimplex2MetalParameters {
    let seed: Int32
    let noise2Variant: OpenSimplex2MetalNoise2Variant
    let noise3Variant: OpenSimplex2MetalNoise3Variant
    let noise4Variant: OpenSimplex2MetalNoise4Variant

    public init(
        seed: Int32,
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

public class OpenSimplex2MetalShaderLoader {
    public let shader: String
    public let functionNames: [String]

    public init(dimensionality: [OpenSimplex2MetalDimensionality]) {
        self.shader = Self.baseShader + dimensionality.map {
            switch $0 {
            case .two: OpenSimplex2MetalNoise2.getFunction()
            case .three: OpenSimplex2MetalNoise3.getFunction()
            case .four: OpenSimplex2MetalNoise4.getFunction()
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

    public static var noise2FunctionName = OpenSimplex2MetalNoise2.functionName
    public static var noise3FunctionName = OpenSimplex2MetalNoise3.functionName
    public static var noise4FunctionName = OpenSimplex2MetalNoise4.functionName

    private static let baseShader = """
    enum class OpenSimplex2MetalNoise2Variant: int8_t {
        standard = 0,
        x = 1,
    };

    enum class OpenSimplex2MetalNoise3Variant: int8_t {
        xy = 0,
        xz = 1,
        fallback = 2,
    };

    enum class OpenSimplex2MetalNoise4Variant: int8_t {
        xyz = 0,
        xyz_xy = 1,
        xyz_xz = 2,
        xy_zw = 3,
        fallback = 4,
    };

    struct OpenSimplex2MetalParameters {
        int seed;
        OpenSimplex2MetalNoise2Variant noise2Variant;
        OpenSimplex2MetalNoise3Variant noise3Variant;
        OpenSimplex2MetalNoise4Variant noise4Variant;
    };

    constant static long const PRIME_X = 0x5205402B9270C86FL;
    constant static long const PRIME_Y = 0x598CD327003817B5L;
    constant static long const PRIME_Z = 0x5BCC226E9FA0BACBL;
    constant static long const PRIME_W = 0x56CC5227E58F554BL;
    constant static long const HASH_MULTIPLIER = 0x53A3F72DEEC546F5L;
    constant static float const UNSKEW_2D = -0.21132486540518713;

    int fastFloor(float x) {
        int xi = (int)x;
        return x < xi ? xi - 1 : xi;
    }

    int fastRound(float x) {
        return x < 0 ? (int)(x - 0.5) : (int)(x + 0.5);
    }

    """
}
