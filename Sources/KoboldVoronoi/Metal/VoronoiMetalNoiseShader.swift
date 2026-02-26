import simd
import Foundation

protocol VoronoiMetalNoiseShader {
    static var baseFunction: String { get }
    static var metalFunction: String { get }
    static var functionName: String { get }

    static func getFunction() -> String
    static func getVariableMap() -> [String: String]
}

extension VoronoiMetalNoiseShader {
    public static func getFunction() -> String {
        return getVariableMap().reduce(baseFunction) { (acc, next) in
            acc.replacingOccurrences(of: "${\(next.key)}", with: next.value)
        } + metalFunction
    }

    static func formatFloat(_ value: Float) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 12

        let number = NSNumber(value: value)
        return formatter.string(from: number)!
    }
}

public enum VoronoiMetalDimensionality {
    case two
    case three
    case four
}

public enum VoronoiMetalDistanceFunction: Int8 {
    case euclidean = 0
    case manhattan = 1
    case chebyshev = 2
    case minkowski = 3
}

public enum VoronoiMetalReturnType: Int8 {
    case distance = 0
    case cellValue = 1
    case distance2 = 2
    case distance2_distance1 = 3
}

public struct VoronoiMetalParameters {
    public let seed: Int32
    public let distanceFunction: VoronoiMetalDistanceFunction
    public let returnType: VoronoiMetalReturnType
    public let jitter: Float
    public let minkowskiP: Float

    public init(
        seed: Int32,
        distanceFunction: VoronoiMetalDistanceFunction = .euclidean,
        returnType: VoronoiMetalReturnType = .distance,
        jitter: Float = 1.0,
        minkowskiP: Float = 2.0
    ) {
        self.seed = seed
        self.distanceFunction = distanceFunction
        self.returnType = returnType
        self.jitter = jitter
        self.minkowskiP = minkowskiP
    }
}

public class VoronoiMetalShaderLoader {
    public let shader: String
    public let functionNames: [String]

    public init(dimensionality: [VoronoiMetalDimensionality]) {
        var shaderComponents: [String] = [Self.loadShaderFile("VoronoiNoiseCommon.metal.txt")]

        if dimensionality.contains(.two) {
            shaderComponents.append(Self.loadShaderFile("VoronoiNoise2.metal.txt"))
        }
        if dimensionality.contains(.three) {
            shaderComponents.append(Self.loadShaderFile("VoronoiNoise3.metal.txt"))
        }
        if dimensionality.contains(.four) {
            shaderComponents.append(Self.loadShaderFile("VoronoiNoise4.metal.txt"))
        }

        self.shader = shaderComponents.joined(separator: "\n")
        self.functionNames = dimensionality.map {
            switch $0 {
            case .two: Self.noise2FunctionName
            case .three: Self.noise3FunctionName
            case .four: Self.noise4FunctionName
            }
        }
    }

    public static func loadShaderFile(_ filename: String) -> String {
        guard let path = Bundle.module.url(
                forResource: filename.replacingOccurrences(of: ".metal.txt", with: ""),
                withExtension: "metal.txt",
                subdirectory: "Shaders"
              ),
              let content = try? String(contentsOf: path, encoding: .utf8
        ) else {
            fatalError("Warning: Could not load shader file \(filename), falling back to inline generation")
        }
        return content
    }

    public static let noise2FunctionName = "voronoiNoise2"
    public static let noise3FunctionName = "voronoiNoise3"
    public static let noise4FunctionName = "voronoiNoise4"
}
