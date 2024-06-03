import XCTest
import simd
@testable import SPMOpenSimplex2

final class SPMOpenSimplex2ImplementationComparison: XCTestCase {
    func testExample() throws {
        let cpuNoise = OpenSimplex2CPU()
        let gpuNoise = OpenSimplex2Metal()

        let noiseCount: Int = 16
        let noiseScale: Float = 0.1

        let noise3Input = (0..<noiseCount)
            .map(Float.init)
            .map { SIMD3<Float>($0 * noiseScale, 0, 0) }

        print("Noise 3 Input:")
        noise3Input.forEach { print(" - \($0)") }

        let noise3OutputCPU = cpuNoise.noise3(seed: 42, coords: noise3Input, variant: .xy)
        let noise3OutputGPU = gpuNoise.noise3(seed: 42, coords: noise3Input, variant: .xy)

        print("Noise 3 Output CPU:")
        noise3OutputCPU.forEach { print("\($0)")}

        print("Noise 3 Output GPU:")
        noise3OutputGPU.forEach { print("\($0)")}

        print("")

    }
}
