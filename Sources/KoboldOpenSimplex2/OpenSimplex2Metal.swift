import Metal
import Foundation

public class OpenSimplex2Metal {
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

        \(OpenSimplex2MetalShaderLoader(dimensionality: [.two, .three, .four]).shader)
        """

        let library = try! device.makeLibrary(source: kernel, options: nil)
        noise2Pipeline = library.makeFunction(name: OpenSimplex2MetalShaderLoader.noise2FunctionName)
            .flatMap {
                try? device.makeComputePipelineState(function: $0)
            }
        noise3Pipeline = library.makeFunction(name: OpenSimplex2MetalShaderLoader.noise3FunctionName)
            .flatMap {
                try? device.makeComputePipelineState(function: $0)
            }
        noise4Pipeline = library.makeFunction(name: OpenSimplex2MetalShaderLoader.noise4FunctionName)
            .flatMap {
                try? device.makeComputePipelineState(function: $0)
            }
    }

    private func executeNoiseFunction(
        pipeline: MTLComputePipelineState,
        openSimplex2NoiseParameters: OpenSimplex2NoiseParameters,
        inBuffer: MTLBuffer,
        inputCount: Int
    ) -> [Float] {
        let outByteLength = MemoryLayout<Float>.stride * inputCount
        let outBuffer = device.makeBuffer(length: outByteLength, options: [.storageModeShared])!

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return []
        }

        var uniforms = openSimplex2NoiseParameters.toMetal()

        commandEncoder.setComputePipelineState(pipeline)
        commandEncoder.setBytes(&uniforms, length: MemoryLayout<OpenSimplex2MetalParameters>.stride, index: 0)
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

extension OpenSimplex2Metal: OpenSimplex2 {
    public func noise2(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coord: SIMD2<Double>) -> Float {
        return noise2(openSimplex2NoiseParameters: openSimplex2NoiseParameters, coords: [SIMD2<Float>(coord)])[0]
    }

    public func noise2(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coords: [SIMD2<Double>]) -> [Float] {
        return noise2(openSimplex2NoiseParameters: openSimplex2NoiseParameters, coords: coords.map(SIMD2<Float>.init))
    }

    public func noise2(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coord: SIMD2<Float>) -> Float {
        return noise2(openSimplex2NoiseParameters: openSimplex2NoiseParameters, coords: [coord])[0]
    }

    public func noise2(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coords: [SIMD2<Float>]) -> [Float] {
        guard let pipeline = noise2Pipeline else {
            return []
        }
        let inByteLength = MemoryLayout<SIMD2<Float>>.stride * coords.count
        let inBuffer = device.makeBuffer(length: inByteLength, options: [.storageModeShared])!
        uploadToBuffer(inBuffer, data: coords, offset: 0)

        return executeNoiseFunction(
            pipeline: pipeline,
            openSimplex2NoiseParameters: openSimplex2NoiseParameters,
            inBuffer: inBuffer,
            inputCount: coords.count)
    }

    public func noise3(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coord: SIMD3<Double>) -> Float {
        return noise3(openSimplex2NoiseParameters: openSimplex2NoiseParameters, coords: [SIMD3<Float>(coord)])[0]
    }

    public func noise3(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coords: [SIMD3<Double>]) -> [Float] {
        return noise3(openSimplex2NoiseParameters: openSimplex2NoiseParameters, coords: coords.map(SIMD3<Float>.init))
    }

    public func noise3(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coord: SIMD3<Float>) -> Float {
        return noise3(openSimplex2NoiseParameters: openSimplex2NoiseParameters, coords: [coord])[0]
    }

    public func noise3(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coords: [SIMD3<Float>]) -> [Float] {
        guard let pipeline = noise3Pipeline else {
            return []
        }
        let inByteLength = MemoryLayout<SIMD3<Float>>.stride * coords.count
        let inBuffer = device.makeBuffer(length: inByteLength, options: [.storageModeShared])!
        uploadToBuffer(inBuffer, data: coords, offset: 0)

        return executeNoiseFunction(
            pipeline: pipeline,
            openSimplex2NoiseParameters: openSimplex2NoiseParameters,
            inBuffer: inBuffer,
            inputCount: coords.count)
    }

    public func noise4(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coord: SIMD4<Double>) -> Float {
        return noise4(openSimplex2NoiseParameters: openSimplex2NoiseParameters, coords: [SIMD4<Float>(coord)])[0]
    }

    public func noise4(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coords: [SIMD4<Double>]) -> [Float] {
        return noise4(openSimplex2NoiseParameters: openSimplex2NoiseParameters, coords: coords.map(SIMD4<Float>.init))
    }

    public func noise4(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coord: SIMD4<Float>) -> Float {
        return noise4(openSimplex2NoiseParameters: openSimplex2NoiseParameters, coords: [coord])[0]
    }

    public func noise4(openSimplex2NoiseParameters: OpenSimplex2NoiseParameters, coords: [SIMD4<Float>]) -> [Float] {
        guard let pipeline = noise4Pipeline else {
            return []
        }
        let inByteLength = MemoryLayout<SIMD4<Float>>.stride * coords.count
        let inBuffer = device.makeBuffer(length: inByteLength, options: [.storageModeShared])!
        uploadToBuffer(inBuffer, data: coords, offset: 0)

        return executeNoiseFunction(
            pipeline: pipeline,
            openSimplex2NoiseParameters: openSimplex2NoiseParameters,
            inBuffer: inBuffer,
            inputCount: coords.count)
    }
}

public extension OpenSimplex2Noise2Variant {
    func toMetal() -> OpenSimplex2MetalNoise2Variant {
        return switch self {
        case .standard: OpenSimplex2MetalNoise2Variant.standard
        case .x: OpenSimplex2MetalNoise2Variant.x
        }
    }
}

public extension OpenSimplex2Noise3Variant {
    func toMetal() -> OpenSimplex2MetalNoise3Variant {
        return switch self {
        case .xy: OpenSimplex2MetalNoise3Variant.xy
        case .xz: OpenSimplex2MetalNoise3Variant.xz
        case .fallback: OpenSimplex2MetalNoise3Variant.fallback
        }
    }
}

public extension OpenSimplex2Noise4Variant {
    func toMetal() -> OpenSimplex2MetalNoise4Variant {
        return switch self {
        case .xyz: OpenSimplex2MetalNoise4Variant.xyz
        case .xyz_xy: OpenSimplex2MetalNoise4Variant.xyz_xy
        case .xyz_xz: OpenSimplex2MetalNoise4Variant.xyz_xz
        case .xy_zw: OpenSimplex2MetalNoise4Variant.xy_zw
        case .fallback: OpenSimplex2MetalNoise4Variant.fallback
        }
    }
}

public extension OpenSimplex2NoiseParameters {
    func toMetal() -> OpenSimplex2MetalParameters {
        return OpenSimplex2MetalParameters(
            seed: self.seed,
            noise2Variant: self.noise2Variant.toMetal(),
            noise3Variant: self.noise3Variant.toMetal(),
            noise4Variant: self.noise4Variant.toMetal())
    }
}
