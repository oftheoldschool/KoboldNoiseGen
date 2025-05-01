import KoboldOpenSimplex2
import simd
import Metal

public class FractalNoiseMetal {
    private let commandQueue: MTLCommandQueue!
    private let device: MTLDevice!

    private let noise2Pipeline: MTLComputePipelineState?
    private let noise3Pipeline: MTLComputePipelineState?
    private let noise4Pipeline: MTLComputePipelineState?

    public init(
        device: MTLDevice = MTLCreateSystemDefaultDevice()!,
        commandQueue: MTLCommandQueue? = nil
    ) {
        self.device = device
        self.commandQueue = commandQueue ?? self.device.makeCommandQueue()

        let kernel = """
        #include <metal_stdlib>
        using namespace metal;

        \(OpenSimplex2MetalShaderLoader(dimensionality: [.two, .three, .four]).shader)

        \(FractalNoiseMetalShaderLoader(dimensionality: [.two, .three, .four]).shader)
        """

        let library = try! self.device.makeLibrary(source: kernel, options: nil)

        noise2Pipeline = library.makeFunction(name: FractalNoiseMetalShaderLoader.noise2FunctionName)
            .flatMap {
                try? device.makeComputePipelineState(function: $0)
            }
        noise3Pipeline = library.makeFunction(name: FractalNoiseMetalShaderLoader.noise3FunctionName)
            .flatMap {
                try? device.makeComputePipelineState(function: $0)
            }
        noise4Pipeline = library.makeFunction(name: FractalNoiseMetalShaderLoader.noise4FunctionName)
            .flatMap {
                try? device.makeComputePipelineState(function: $0)
            }
    }

    private func executeNoiseFunction<T>(
        pipeline: MTLComputePipelineState,
        fractalNoiseParameters: FractalNoiseParameters,
        data: [T]
    ) -> [Float] {
        let inputCount = data.count

        let outByteLength = MemoryLayout<Float>.stride * inputCount
        let outBuffer = device.makeBuffer(length: outByteLength, options: [.storageModeShared])!

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return []
        }

        var uniforms = FractalNoiseMetalParameters(fractalNoiseParameters: fractalNoiseParameters)

        commandEncoder.setComputePipelineState(pipeline)
        commandEncoder.setBytes(&uniforms, length: MemoryLayout<FractalNoiseMetalParameters>.stride, index: 0)

        let inByteLength = MemoryLayout<T>.stride * inputCount
        if inByteLength < 4 * 1024 {
            data.withUnsafeBytes { rawBufferPointer in
                commandEncoder.setBytes(rawBufferPointer.baseAddress!, length: inByteLength, index: 1)
            }
        } else {
            let inBuffer = device.makeBuffer(length: inByteLength, options: [.storageModeShared])!
            uploadToBuffer(inBuffer, data: data, offset: 0)
            commandEncoder.setBuffer(inBuffer, offset: 0, index: 1)
        }
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

extension FractalNoiseMetal: FractalNoise {
    public func noise3(
        fractalNoiseParameters: FractalNoiseParameters,
        coord: SIMD3<Float>
    ) -> Float {
        return noise3(
            fractalNoiseParameters: fractalNoiseParameters,
            coords: [coord])[0]
    }

    public func noise3(
        fractalNoiseParameters: FractalNoiseParameters,
        coords: [SIMD3<Float>]
    ) -> [Float] {
        guard let pipeline = noise3Pipeline else {
            return []
        }
        return executeNoiseFunction(
            pipeline: pipeline,
            fractalNoiseParameters: fractalNoiseParameters,
            data: coords)
    }
}

