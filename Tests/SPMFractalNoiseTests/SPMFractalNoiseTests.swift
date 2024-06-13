import XCTest
@testable import SPMFractalNoise

final class SPMFractalNoiseTests: XCTestCase {
    func testExample() throws {
        let device = MTLCreateSystemDefaultDevice()!
        let fractalNoise = FractalNoiseMetal(device: device)

        let imageSize = 1024
        let imageScale: Float = 1

        let fractalNoiseParameters = FractalNoiseParameters(
            noiseTypeParameters: .OpenSimplex2(
                OpenSimplex2NoiseParameters(
                    seed: 420,
                    noise3Variant: .xz)),
            octaves: 8,
            lacunarity: 2,
            hurstExponent: 1,
            startingAmplitude: 1,
            startingFrequency: 0.0025,
            coordinateScale: 0.5,
            warpIterations: 3,
            warpScale: 200)

        var outputString = "P2\n\(imageSize) \(imageSize)\n255\n"

        let coords = (0..<imageSize).flatMap {
            y in (0..<imageSize).map {
                x in
                SIMD3<Float>(Float(x), Float(y), 0) * imageScale
            }
        }

        let noise = fractalNoise.noise3(
            fractalNoiseParameters: fractalNoiseParameters,
            coords: coords)

        var lowest: Int = 0
        var highest: Int = 0
        for y in 0..<imageSize {
            var rowString = ""
            let row = noise[(y * imageSize)..<((y+1) * imageSize)]
            for x in 0..<imageSize {
                let noise = row[row.startIndex + x]
                let scaledNoise = Int((noise + 1) * 128)
                if scaledNoise < lowest {
                    lowest = scaledNoise
                }
                if scaledNoise > highest {
                    highest = scaledNoise
                }
                rowString += "\(scaledNoise) "
            }
            outputString += "\(rowString)\n"
        }

        print(outputString)
        print("lowest:   \(lowest)")
        print("hightest: \(highest)")
    }
}
