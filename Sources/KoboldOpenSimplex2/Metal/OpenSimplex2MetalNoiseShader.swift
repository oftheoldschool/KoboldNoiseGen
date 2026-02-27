import Foundation
import simd

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
    public let seed: Int32
    public let noise2Variant: OpenSimplex2MetalNoise2Variant
    public let noise3Variant: OpenSimplex2MetalNoise3Variant
    public let noise4Variant: OpenSimplex2MetalNoise4Variant

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
        var shaderComponents: [String] = [Self.loadShaderFile("OpenSimplex2NoiseCommon.metal.txt")]

        if dimensionality.contains(.two) {
            shaderComponents.append(Self.loadShaderFile("OpenSimplex2Noise2.metal.txt"))
        }
        if dimensionality.contains(.three) {
            shaderComponents.append(Self.loadShaderFile("OpenSimplex2Noise3.metal.txt"))
        }
        if dimensionality.contains(.four) {
            shaderComponents.append(Self.loadShaderFile("OpenSimplex2Noise4.metal.txt"))
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
        #if SWIFT_PACKAGE
        // Try Swift Package Manager's resource bundle first
        if let url = Bundle.module.url(
            forResource: filename.replacingOccurrences(of: ".metal.txt", with: ""),
            withExtension: "metal.txt",
            subdirectory: "Shaders"
        ), let content = try? String(contentsOf: url, encoding: .utf8) {
            return content
        }
        #endif

        // Fallback 2: Try the bundle associated with this type (useful when packaged as a framework)
        if let url = Bundle(for: OpenSimplex2MetalShaderLoader.self).url(
            forResource: filename.replacingOccurrences(of: ".metal.txt", with: ""),
            withExtension: "metal.txt",
            subdirectory: "Shaders"
        ), let content = try? String(contentsOf: url, encoding: .utf8) {
            return content
        }

        // Fallback 3: Try the main bundle (useful when resources are copied into the app target)
        if let url = Bundle.main.url(
            forResource: filename.replacingOccurrences(of: ".metal.txt", with: ""),
            withExtension: "metal.txt",
            subdirectory: "Shaders"
        ), let content = try? String(contentsOf: url, encoding: .utf8) {
            return content
        }

        fatalError("Warning: Could not load shader file \(filename) from Bundle.module, framework bundle, or main bundle")
    }

    public static let noise2FunctionName = "openSimplexNoise2"
    public static let noise3FunctionName = "openSimplexNoise3"
    public static let noise4FunctionName = "openSimplexNoise4"
}
