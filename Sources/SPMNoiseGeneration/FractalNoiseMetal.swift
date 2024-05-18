import SPMOpenSimplex2
import simd
import Metal

public class FractalNoiseMetal {
    private let commandQueue: MTLCommandQueue!
    private let device: MTLDevice!

    private let noise2Pipeline: MTLComputePipelineState?
    private let noise3Pipeline: MTLComputePipelineState?
    private let noise4Pipeline: MTLComputePipelineState?

    public init(
        device: MTLDevice? = nil,
        commandQueue: MTLCommandQueue? = nil
    ) {
        self.device = device ?? MTLCreateSystemDefaultDevice()!
        self.commandQueue = commandQueue ?? self.device.makeCommandQueue()

        let kernel = """
        #include <metal_stdlib>
        using namespace metal;

        \(OpenSimplex2MetalShaderLoader(dimensionality: [.two, .three, .four]).shader)

        \(FractalNoiseMetalShaderLoader(dimensionality: [.two, .three, .four]).shader)
        """

        let library = try! self.device.makeLibrary(source: kernel, options: nil)

        if let noise2Function = library.makeFunction(name: FractalNoiseMetalShaderLoader.noise2FunctionName) {
            noise2Pipeline = try! self.device.makeComputePipelineState(function: noise2Function)
        } else {
            noise2Pipeline = nil
        }
        if let noise3Function = library.makeFunction(name: FractalNoiseMetalShaderLoader.noise3FunctionName) {
            noise3Pipeline = try! self.device.makeComputePipelineState(function: noise3Function)
        } else {
            noise3Pipeline = nil
        }
        if let noise4Function = library.makeFunction(name: FractalNoiseMetalShaderLoader.noise4FunctionName) {
            noise4Pipeline = try! self.device.makeComputePipelineState(function: noise4Function)
        } else {
            noise4Pipeline = nil
        }
    }

    private func executeNoiseFunction(
        pipeline: MTLComputePipelineState,
        seed: Int32,
        fractalNoiseParameters: FractalNoiseParameters,
        inBuffer: MTLBuffer,
        inputCount: Int
    ) -> [Float] {
        let outByteLength = MemoryLayout<Float>.stride * inputCount
        let outBuffer = device.makeBuffer(length: outByteLength, options: [.storageModeShared])!

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return []
        }

        let (noiseType, noiseTypeParameters) = switch fractalNoiseParameters.noiseTypeParameters {
        case .OpenSimplex2(let params):
            (FractalNoiseMetalType.OpenSimplex2,
             FractalNoiseMetalTypeParameters.OpenSimplex2(
                OpenSimplex2MetalParameters(
                    seed: seed,
                    noise2Variant: params.openSimplex2Variant.toMetalVariant(),
                    noise3Variant: params.openSimplex3Variant.toMetalVariant(),
                    noise4Variant: params.openSimplex4Variant.toMetalVariant())))
        }

        var uniforms = FractalNoiseMetalParameters(
            lacunarity: fractalNoiseParameters.lacunarity,
            gain: exp2(-fractalNoiseParameters.hurstExponent),
            startingAmplitude: fractalNoiseParameters.startingAmplitude,
            startingFrequency: fractalNoiseParameters.startingFrequency,
            octaves: fractalNoiseParameters.octaves,
            noiseType: noiseType,
            noiseTypeParameters: noiseTypeParameters)

        commandEncoder.setComputePipelineState(pipeline)
        commandEncoder.setBytes(&uniforms, length: MemoryLayout<FractalNoiseMetalParameters>.stride, index: 0)
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

extension FractalNoiseMetal: FractalNoise {
    public func noise3(
        seed: Int32,
        coord: SIMD3<Float>,
        fractalNoiseParameters: FractalNoiseParameters
    ) -> Float {
        return noise3(
            seed: seed,
            coords: [coord],
            fractalNoiseParameters: fractalNoiseParameters)[0]
    }

    public func noise3(
        seed: Int32,
        coords: [SIMD3<Float>],
        fractalNoiseParameters: FractalNoiseParameters
    ) -> [Float] {
        guard let pipeline = noise3Pipeline else {
            return []
        }
        let inByteLength = MemoryLayout<SIMD3<Float>>.stride * coords.count
        let inBuffer = device.makeBuffer(length: inByteLength, options: [.storageModeShared])!
        uploadToBuffer(inBuffer, data: coords, offset: 0)

        return executeNoiseFunction(
            pipeline: pipeline,
            seed: seed,
            fractalNoiseParameters: fractalNoiseParameters,
            inBuffer: inBuffer,
            inputCount: coords.count)
    }
}
