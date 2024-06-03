import XCTest
import simd
@testable import SPMOpenSimplex2

final class SPMOpenSimplex2ImageTests: XCTestCase {
    func testExample() throws {
        let device = MTLCreateSystemDefaultDevice()!
        let noiseMachine = OpenSimplex2Metal(device: device)

        let seed: Int32 = 42
        let imageSize = 1024
        let imageScale: Float = 0.1

        var outputString = "P2\n\(imageSize) \(imageSize)\n255\n"

        let input = (0..<imageSize).flatMap {
            y in (0..<imageSize).map {
                x in
                SIMD3<Float>(Float(x), Float(y), 0) * imageScale
            }
        }

        let noise = noiseMachine.noise3(
            seed: seed,
            coords: input,
            variant: .xz)

        for y in 0..<imageSize {
            var rowString = ""
            let row = noise[(y * imageSize)..<((y+1) * imageSize)]
            for x in 0..<imageSize {
                let noise = row[row.startIndex + x]
                let scaledNoise = Int((noise + 1) * 128)
                rowString += "\(scaledNoise) "
            }
            outputString += "\(rowString)\n"
        }

        print(outputString)
    }
}
