
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
        if let noise2Function = library.makeFunction(name: OpenSimplex2MetalShaderLoader.noise2FunctionName) {
            noise2Pipeline = try! device.makeComputePipelineState(function: noise2Function)
        } else {
            noise2Pipeline = nil
        }
        if let noise3Function = library.makeFunction(name: OpenSimplex2MetalShaderLoader.noise3FunctionName) {
            noise3Pipeline = try! device.makeComputePipelineState(function: noise3Function)
        } else {
            noise3Pipeline = nil
        }
        if let noise4Function = library.makeFunction(name: OpenSimplex2MetalShaderLoader.noise4FunctionName) {
            noise4Pipeline = try! device.makeComputePipelineState(function: noise4Function)
        } else {
            noise4Pipeline = nil
        }
    }

    private func executeNoiseFunction(
        pipeline: MTLComputePipelineState,
        seed: Int32,
        noise2Variant: OpenSimplex2Noise2Variant = .standard,
        noise3Variant: OpenSimplex2Noise3Variant = .xy,
        noise4Variant: OpenSimplex2Noise4Variant = .xyz,
        inBuffer: MTLBuffer,
        inputCount: Int
    ) -> [Float] {
        let outByteLength = MemoryLayout<Float>.stride * inputCount
        let outBuffer = device.makeBuffer(length: outByteLength, options: [.storageModeShared])!

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return []
        }

        var uniforms = OpenSimplex2MetalParameters(
            seed: seed,
            noise2Variant: noise2Variant.toMetalVariant(),
            noise3Variant: noise3Variant.toMetalVariant(),
            noise4Variant: noise4Variant.toMetalVariant())

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

        let gridSize = MTLSize(width: groupWidth * finalGroupCount, height: 1, depth: 1)

        commandEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: groupSize)

        commandEncoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        return downloadFromBuffer(outBuffer, count: inputCount)
    }

    private func uploadToBuffer<T>(_ buffer: MTLBuffer, data: [T], offset: Int = 0) {
        let memoryPointer = buffer.contents().advanced(by: offset)
        memcpy(memoryPointer, data, MemoryLayout<T>.stride * data.count)
    }

    private func downloadFromBuffer<T>(_ buffer: MTLBuffer, count: Int, offset: Int = 0) -> [T] {
        let memoryPointer = buffer.contents().advanced(by: offset)
        let typedPointer = memoryPointer.bindMemory(to: T.self, capacity: MemoryLayout<T>.stride * count)
        let bufferedPointer = UnsafeBufferPointer(start: typedPointer, count: count)
        return Array(bufferedPointer)
    }
}

extension OpenSimplex2Metal: OpenSimplex2 {
    public func noise2(seed: Int32, coord: SIMD2<Double>, variant: OpenSimplex2Noise2Variant) -> Float {
        return noise2(seed: seed, coords: [SIMD2<Float>(coord)], variant: variant)[0]
    }

    public func noise2(seed: Int32, coords: [SIMD2<Double>], variant: OpenSimplex2Noise2Variant) -> [Float] {
        return noise2(seed: seed, coords: coords.map(SIMD2<Float>.init), variant: variant)
    }

    public func noise2(seed: Int32, coord: SIMD2<Float>, variant: OpenSimplex2Noise2Variant) -> Float {
        return noise2(seed: seed, coords: [coord], variant: variant)[0]
    }

    public func noise2(seed: Int32, coords: [SIMD2<Float>], variant: OpenSimplex2Noise2Variant) -> [Float] {
        guard let pipeline = noise2Pipeline else {
            return []
        }
        let inByteLength = MemoryLayout<SIMD2<Float>>.stride * coords.count
        let inBuffer = device.makeBuffer(length: inByteLength, options: [.storageModeShared])!
        uploadToBuffer(inBuffer, data: coords, offset: 0)

        return executeNoiseFunction(
            pipeline: pipeline,
            seed: seed,
            noise2Variant: variant,
            inBuffer: inBuffer,
            inputCount: coords.count)
    }

    public func noise3(seed: Int32, coord: SIMD3<Double>, variant: OpenSimplex2Noise3Variant) -> Float {
        return noise3(seed: seed, coords: [SIMD3<Float>(coord)], variant: variant)[0]
    }

    public func noise3(seed: Int32, coords: [SIMD3<Double>], variant: OpenSimplex2Noise3Variant) -> [Float] {
        return noise3(seed: seed, coords: coords.map(SIMD3<Float>.init), variant: variant)
    }

    public func noise3(seed: Int32, coord: SIMD3<Float>, variant: OpenSimplex2Noise3Variant) -> Float {
        return noise3(seed: seed, coords: [coord], variant: variant)[0]
    }

    public func noise3(seed: Int32, coords: [SIMD3<Float>], variant: OpenSimplex2Noise3Variant) -> [Float] {
        guard let pipeline = noise3Pipeline else {
            return []
        }
        let inByteLength = MemoryLayout<SIMD3<Float>>.stride * coords.count
        let inBuffer = device.makeBuffer(length: inByteLength, options: [.storageModeShared])!
        uploadToBuffer(inBuffer, data: coords, offset: 0)

        return executeNoiseFunction(
            pipeline: pipeline,
            seed: seed,
            noise3Variant: variant,
            inBuffer: inBuffer,
            inputCount: coords.count)
    }

    public func noise4(seed: Int32, coord: SIMD4<Double>, variant: OpenSimplex2Noise4Variant) -> Float {
        return noise4(seed: seed, coords: [SIMD4<Float>(coord)], variant: variant)[0]
    }

    public func noise4(seed: Int32, coords: [SIMD4<Double>], variant: OpenSimplex2Noise4Variant) -> [Float] {
        return noise4(seed: seed, coords: coords.map(SIMD4<Float>.init), variant: variant)
    }

    public func noise4(seed: Int32, coord: SIMD4<Float>, variant: OpenSimplex2Noise4Variant) -> Float {
        return noise4(seed: seed, coords: [coord], variant: variant)[0]
    }

    public func noise4(
        seed: Int32,
        coords: [SIMD4<Float>],
        variant: OpenSimplex2Noise4Variant
    ) -> [Float] {
        guard let pipeline = noise4Pipeline else {
            return []
        }
        let inByteLength = MemoryLayout<SIMD4<Float>>.stride * coords.count
        let inBuffer = device.makeBuffer(length: inByteLength, options: [.storageModeShared])!
        uploadToBuffer(inBuffer, data: coords, offset: 0)

        return executeNoiseFunction(
            pipeline: pipeline,
            seed: seed,
            noise4Variant: variant,
            inBuffer: inBuffer,
            inputCount: coords.count)
    }
}

public extension OpenSimplex2Noise2Variant {
    func toMetalVariant() -> OpenSimplex2MetalNoise2Variant {
        return switch self {
        case .standard: OpenSimplex2MetalNoise2Variant.standard
        case .x: OpenSimplex2MetalNoise2Variant.x
        }
    }
}

public extension OpenSimplex2Noise3Variant {
    func toMetalVariant() -> OpenSimplex2MetalNoise3Variant {
        return switch self {
        case .xy: OpenSimplex2MetalNoise3Variant.xy
        case .xz: OpenSimplex2MetalNoise3Variant.xz
        case .fallback: OpenSimplex2MetalNoise3Variant.fallback
        }
    }
}

public extension OpenSimplex2Noise4Variant {
    func toMetalVariant() -> OpenSimplex2MetalNoise4Variant {
        return switch self {
        case .xyz: OpenSimplex2MetalNoise4Variant.xyz
        case .xyz_xy: OpenSimplex2MetalNoise4Variant.xyz_xy
        case .xyz_xz: OpenSimplex2MetalNoise4Variant.xyz_xz
        case .xy_zw: OpenSimplex2MetalNoise4Variant.xy_zw
        case .fallback: OpenSimplex2MetalNoise4Variant.fallback
        }
    }
}

