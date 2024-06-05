public class FractalNoiseMetalNoise3: FractalNoiseMetalNoiseShader {
    static var functionName: String = "fractalNoise3"

    static var metalFunction: String =
"""
    kernel void \(functionName)(
        constant FractalNoiseMetalParameters &uniforms [[ buffer(0) ]],
        constant const float3 * in                     [[ buffer(1) ]],
        device float * out                             [[ buffer(2) ]],
        uint2 thread_position_in_grid                  [[ thread_position_in_grid ]]
    ) {
        int index = thread_position_in_grid.x;

        out[index] = fbm3(uniforms, in[index]);
    }

"""

    static var metalFunctionWithNormal: String? = nil

    static var functionWithNormalName: String? = nil

    static var baseFunction: String =
"""
    float fbm3(
        constant FractalNoiseMetalParameters &uniforms,
        float3 inCoord
    ) {
        float amplitude = uniforms.startingAmplitude;
        float frequency = uniforms.startingFrequency;
        float gain = uniforms.gain;
        float lacunarity = uniforms.lacunarity;

        float fractalNoise = 0;

        int seed = uniforms.noiseTypeParameters.openSimplex2Parameters.seed;
        float (*openSimplexFunction)(long, float, float, float);

        switch (uniforms.noiseTypeParameters.openSimplex2Parameters.noise3Variant) {
            case OpenSimplex2MetalNoise3Variant::xy:
                openSimplexFunction = noise3_ImproveXY;
                break;
            case OpenSimplex2MetalNoise3Variant::xz:
                openSimplexFunction = noise3_ImproveXZ;
                break;
            case OpenSimplex2MetalNoise3Variant::fallback:
                openSimplexFunction = noise3_Fallback;
                break;
        }

        for (int i = 0; i < uniforms.octaves; ++i) {
            float3 scaledCoord = inCoord * frequency;

            fractalNoise *= (1 / (amplitude + 1));
            fractalNoise += amplitude * openSimplexFunction(
                seed,
                scaledCoord.x,
                scaledCoord.y,
                scaledCoord.z);

            frequency *= lacunarity;
            amplitude *= gain;
        }

        return min(max(fractalNoise, -1.f), 1.f);
    }

"""
}

