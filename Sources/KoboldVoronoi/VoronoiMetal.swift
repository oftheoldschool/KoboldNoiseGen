import Metal
import Foundation

public class VoronoiMetal {
    private let commandQueue: MTLCommandQueue!
    private let device: MTLDevice!

    private let noise2Pipeline: MTLComputePipelineState?
    private let noise3Pipeline: MTLComputePipelineState?
    private let noise4Pipeline: MTLComputePipelineState?

    public init(device: MTLDevice = MTLCreateSystemDefaultDevice()!) {
        self.device = device
        self.commandQueue = self.device.makeCommandQueue()

        let kernel = """
        #include <metal_stdlib>
        using namespace metal;

        \(VoronoiMetalShaderLoader(dimensionality: [.two, .three, .four]).shader)
        """

        let library = try! device.makeLibrary(source: kernel, options: nil)
        noise2Pipeline = library.makeFunction(name: VoronoiMetalShaderLoader.noise2FunctionName)
            .flatMap {
                try? device.makeComputePipelineState(function: $0)
            }
        noise3Pipeline = library.makeFunction(name: VoronoiMetalShaderLoader.noise3FunctionName)
            .flatMap {
                try? device.makeComputePipelineState(function: $0)
            }
        noise4Pipeline = library.makeFunction(name: VoronoiMetalShaderLoader.noise4FunctionName)
            .flatMap {
                try? device.makeComputePipelineState(function: $0)
            }
    }

    private func executeNoiseFunction(
        pipeline: MTLComputePipelineState,
        voronoiNoiseParameters: VoronoiNoiseParameters,
        inBuffer: MTLBuffer,
        inputCount: Int
    ) -> [Float] {
        let outByteLength = MemoryLayout<Float>.stride * inputCount
        let outBuffer = device.makeBuffer(length: outByteLength, options: [.storageModeShared])!

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return []
        }

        var uniforms = voronoiNoiseParameters.toMetal()

        commandEncoder.setComputePipelineState(pipeline)
        commandEncoder.setBytes(&uniforms, length: MemoryLayout<VoronoiMetalParameters>.stride, index: 0)
        commandEncoder.setBuffer(inBuffer, offset: 0, index: 1)
        commandEncoder.setBuffer(outBuffer, offset: 0, index: 2)

        let groupWidth = inputCount > pipeline.maxTotalThreadsPerThreadgroup
        ? pipeline.maxTotalThreadsPerThreadgroup
        : inputCount
        let groupSize = MTLSize(width: groupWidth, height: 1, depth: 1)

        let (groupCount, groupCountRemainder) = inputCount.quotientAndRemainder(dividingBy: groupWidth)
        let finalGroupCount = groupCount + (groupCountRemainder > 0 ? 1 : 0)

        if #available(iOS 14.0, macOS 11.0, *), device.supportsFamily(.apple4) {
            let gridSize = MTLSize(width: groupWidth * finalGroupCount, height: 1, depth: 1)
            commandEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: groupSize)
        } else {
            let gridSize = MTLSize(width: finalGroupCount, height: 1, depth: 1)
            commandEncoder.dispatchThreadgroups(gridSize, threadsPerThreadgroup: groupSize)
        }

        commandEncoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        return downloadFromBuffer(outBuffer, count: inputCount)
    }

    private func uploadToBuffer<T>(_ buffer: MTLBuffer, data: [T], offset: Int = 0) {
        let memoryPointer = buffer.contents().advanced(by: offset)
        let typedPointer = memoryPointer.bindMemory(to: T.self, capacity: data.count)
        for (index, element) in data.enumerated() {
            typedPointer[index] = element
        }
    }

    private func downloadFromBuffer<T>(_ buffer: MTLBuffer, count: Int, offset: Int = 0) -> [T] {
        let memoryPointer = buffer.contents().advanced(by: offset)
        let typedPointer = memoryPointer.bindMemory(to: T.self, capacity: MemoryLayout<T>.stride * count)
        let bufferedPointer = UnsafeBufferPointer(start: typedPointer, count: count)
        return Array(bufferedPointer)
    }
}

extension VoronoiMetal: Voronoi {
    public func noise2(voronoiNoiseParameters: VoronoiNoiseParameters, coord: SIMD2<Double>) -> Float {
        return noise2(voronoiNoiseParameters: voronoiNoiseParameters, coords: [SIMD2<Float>(coord)])[0]
    }

    public func noise2(voronoiNoiseParameters: VoronoiNoiseParameters, coords: [SIMD2<Double>]) -> [Float] {
        return noise2(voronoiNoiseParameters: voronoiNoiseParameters, coords: coords.map(SIMD2<Float>.init))
    }

    public func noise2(voronoiNoiseParameters: VoronoiNoiseParameters, coord: SIMD2<Float>) -> Float {
        return noise2(voronoiNoiseParameters: voronoiNoiseParameters, coords: [coord])[0]
    }

    public func noise2(voronoiNoiseParameters: VoronoiNoiseParameters, coords: [SIMD2<Float>]) -> [Float] {
        guard let pipeline = noise2Pipeline else {
            return []
        }
        let inByteLength = MemoryLayout<SIMD2<Float>>.stride * coords.count
        let inBuffer = device.makeBuffer(length: inByteLength, options: [.storageModeShared])!
        uploadToBuffer(inBuffer, data: coords, offset: 0)

        return executeNoiseFunction(
            pipeline: pipeline,
            voronoiNoiseParameters: voronoiNoiseParameters,
            inBuffer: inBuffer,
            inputCount: coords.count)
    }

    public func noise3(voronoiNoiseParameters: VoronoiNoiseParameters, coord: SIMD3<Double>) -> Float {
        return noise3(voronoiNoiseParameters: voronoiNoiseParameters, coords: [SIMD3<Float>(coord)])[0]
    }

    public func noise3(voronoiNoiseParameters: VoronoiNoiseParameters, coords: [SIMD3<Double>]) -> [Float] {
        return noise3(voronoiNoiseParameters: voronoiNoiseParameters, coords: coords.map(SIMD3<Float>.init))
    }

    public func noise3(voronoiNoiseParameters: VoronoiNoiseParameters, coord: SIMD3<Float>) -> Float {
        return noise3(voronoiNoiseParameters: voronoiNoiseParameters, coords: [coord])[0]
    }

    public func noise3(voronoiNoiseParameters: VoronoiNoiseParameters, coords: [SIMD3<Float>]) -> [Float] {
        guard let pipeline = noise3Pipeline else {
            return []
        }
        let inByteLength = MemoryLayout<SIMD3<Float>>.stride * coords.count
        let inBuffer = device.makeBuffer(length: inByteLength, options: [.storageModeShared])!
        uploadToBuffer(inBuffer, data: coords, offset: 0)

        return executeNoiseFunction(
            pipeline: pipeline,
            voronoiNoiseParameters: voronoiNoiseParameters,
            inBuffer: inBuffer,
            inputCount: coords.count)
    }

    public func noise4(voronoiNoiseParameters: VoronoiNoiseParameters, coord: SIMD4<Double>) -> Float {
        return noise4(voronoiNoiseParameters: voronoiNoiseParameters, coords: [SIMD4<Float>(coord)])[0]
    }

    public func noise4(voronoiNoiseParameters: VoronoiNoiseParameters, coords: [SIMD4<Double>]) -> [Float] {
        return noise4(voronoiNoiseParameters: voronoiNoiseParameters, coords: coords.map(SIMD4<Float>.init))
    }

    public func noise4(voronoiNoiseParameters: VoronoiNoiseParameters, coord: SIMD4<Float>) -> Float {
        return noise4(voronoiNoiseParameters: voronoiNoiseParameters, coords: [coord])[0]
    }

    public func noise4(voronoiNoiseParameters: VoronoiNoiseParameters, coords: [SIMD4<Float>]) -> [Float] {
        guard let pipeline = noise4Pipeline else {
            return []
        }
        let inByteLength = MemoryLayout<SIMD4<Float>>.stride * coords.count
        let inBuffer = device.makeBuffer(length: inByteLength, options: [.storageModeShared])!
        uploadToBuffer(inBuffer, data: coords, offset: 0)

        return executeNoiseFunction(
            pipeline: pipeline,
            voronoiNoiseParameters: voronoiNoiseParameters,
            inBuffer: inBuffer,
            inputCount: coords.count)
    }
}

public extension VoronoiDistanceFunction {
    func toMetal() -> VoronoiMetalDistanceFunction {
        switch self {
        case .euclidean: return .euclidean
        case .manhattan: return .manhattan
        case .chebyshev: return .chebyshev
        case .minkowski(_): return .minkowski
        }
    }
    
    func getMinkowskiP() -> Float {
        switch self {
        case .minkowski(let p): return p
        default: return 2.0
        }
    }
}

public extension VoronoiReturnType {
    func toMetal() -> VoronoiMetalReturnType {
        switch self {
        case .distance: return .distance
        case .cellValue: return .cellValue
        case .distance2: return .distance2
        case .distance2MinusDistance1: return .distance2_distance1
        }
    }
}

public extension VoronoiNoiseParameters {
    func toMetal() -> VoronoiMetalParameters {
        return VoronoiMetalParameters(
            seed: self.seed,
            distanceFunction: self.distanceFunction.toMetal(),
            returnType: self.returnType.toMetal(),
            jitter: self.jitter,
            minkowskiP: self.distanceFunction.getMinkowskiP())
    }
}
