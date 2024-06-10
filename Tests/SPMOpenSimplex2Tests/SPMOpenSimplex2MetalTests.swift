import XCTest
import simd
@testable import SPMOpenSimplex2

final class SPMOpenSimplex2MetalTests: XCTestCase {
    func testExample() throws {
        let noiseMachine = OpenSimplex2Metal()
        let openSimplex2NoiseParameters = OpenSimplex2NoiseParameters(
            seed: 42,
            noise2Variant: .standard,
            noise3Variant: .xy,
            noise4Variant: .xyz)

        let noise2Input = (0..<8)
            .map(Float.init)
            .map { SIMD2<Float>($0, $0 + 1) }

        print("Noise 2 Input:")
        noise2Input.forEach { print(" - \($0)") }

        let noise2Output = noiseMachine.noise2(openSimplex2NoiseParameters: openSimplex2NoiseParameters, coords: noise2Input)

        print("Noise 2 Output:")
        noise2Output.forEach { print(" - \($0)")}

        print("")

        let noise3Input = (0..<8)
            .map(Float.init)
            .map { SIMD3<Float>($0, $0 + 1, $0 + 2) }

        print("Noise 3 Input:")
        noise3Input.forEach { print(" - \($0)") }

        let noise3Output = noiseMachine.noise3(openSimplex2NoiseParameters: openSimplex2NoiseParameters, coords: noise3Input)

        print("Noise 3 Output:")
        noise3Output.forEach { print(" - \($0)")}

        print("")

        let noise4Input = (0..<8)
            .map(Float.init)
            .map { SIMD4<Float>($0, $0 + 1, $0 + 2, $0 + 3) }

        print("Noise 4 Input:")
        noise4Input.forEach { print(" - \($0)") }

        let noise4Output = noiseMachine.noise4(openSimplex2NoiseParameters: openSimplex2NoiseParameters, coords: noise4Input)

        print("Noise 4 Output:")
        noise4Output.forEach { print(" - \($0)")}

        print("")
    }
}
