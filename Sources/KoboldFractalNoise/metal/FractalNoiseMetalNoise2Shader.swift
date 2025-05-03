public class FractalNoiseMetalNoise2: FractalNoiseMetalNoiseShader {
    static var functionName: String = "fractalNoise2"

    static var metalFunction: String =
"""
    kernel void \(functionName)(
        constant FractalNoiseMetalParameters &uniforms [[ buffer(0) ]],
        constant const float2 * in                     [[ buffer(1) ]],
        device float * out                             [[ buffer(2) ]],
        constant uint & dataCount                      [[ buffer(3) ]],
        uint2 thread_position_in_grid                  [[ thread_position_in_grid ]],
        uint2 threads_per_grid                         [[ threads_per_grid ]]
    ) {
        uint index = thread_position_in_grid.x;
    }

"""

    static var metalFunctionWithNormal: String? = nil

    static var functionWithNormalName: String? = nil

    static var baseFunction: String =
"""
"""
}

