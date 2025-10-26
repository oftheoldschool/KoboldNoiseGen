import Foundation
import simd
import KoboldOpenSimplex2
import KoboldVoronoi

protocol FractalNoiseMetalNoiseShader {
    static var functionName: String { get }
}

public enum FractalNoiseMetalType: Int8 {
    case OpenSimplex2
    case Voronoi
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

    let noiseType: FractalNoiseMetalType
    
    // OpenSimplex2 parameters
    let openSimplex2Seed: Int32
    let openSimplex2Noise2Variant: OpenSimplex2MetalNoise2Variant
    let openSimplex2Noise3Variant: OpenSimplex2MetalNoise3Variant
    let openSimplex2Noise4Variant: OpenSimplex2MetalNoise4Variant
    
    // Voronoi parameters
    let voronoiSeed: Int32
    let voronoiDistanceFunction: VoronoiMetalDistanceFunction
    let voronoiReturnType: VoronoiMetalReturnType
    let voronoiJitter: Float
    let voronoiMinkowskiP: Float
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
        case .openSimplex2(let openSimplexParams):
            self.noiseType = .OpenSimplex2
            let metalParams = openSimplexParams.toMetal()
            self.openSimplex2Seed = metalParams.seed
            self.openSimplex2Noise2Variant = metalParams.noise2Variant
            self.openSimplex2Noise3Variant = metalParams.noise3Variant
            self.openSimplex2Noise4Variant = metalParams.noise4Variant
            // Set defaults for unused Voronoi parameters
            self.voronoiSeed = 0
            self.voronoiDistanceFunction = .euclidean
            self.voronoiReturnType = .distance
            self.voronoiJitter = 0.0
            self.voronoiMinkowskiP = 0.0
            
        case .voronoi(let voronoiParams):
            self.noiseType = .Voronoi
            let metalParams = voronoiParams.toMetal()
            self.voronoiSeed = metalParams.seed
            self.voronoiDistanceFunction = metalParams.distanceFunction
            self.voronoiReturnType = metalParams.returnType
            self.voronoiJitter = metalParams.jitter
            self.voronoiMinkowskiP = metalParams.minkowskiP
            // Set defaults for unused OpenSimplex2 parameters
            self.openSimplex2Seed = 0
            self.openSimplex2Noise2Variant = .standard
            self.openSimplex2Noise3Variant = .xy
            self.openSimplex2Noise4Variant = .xyz
        }
    }
}

public class FractalNoiseMetalShaderLoader {
    public let shader: String
    public let functionNames: [String]

    public init(dimensionality: [OpenSimplex2MetalDimensionality]) {
        var shaderComponents: [String] = [Self.loadShaderFile("FractalNoiseCommon.metal.txt")]

        if dimensionality.contains(.two) {
            shaderComponents.append(Self.loadShaderFile("FractalNoise2.metal.txt"))
        }
        if dimensionality.contains(.three) {
            shaderComponents.append(Self.loadShaderFile("FractalNoise3.metal.txt"))
        }
        if dimensionality.contains(.four) {
            shaderComponents.append(Self.loadShaderFile("FractalNoise4.metal.txt"))
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

    public static var noise2FunctionName = "fractalNoise2"
    public static var noise3FunctionName = "fractalNoise3"
    public static var noise4FunctionName = "fractalNoise4"
}
