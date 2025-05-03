public class FractalNoiseMetalNoise3: FractalNoiseMetalNoiseShader {
    static var functionName: String = "fractalNoise3"

    static var metalFunction: String =
"""
    kernel void \(functionName)(
        constant FractalNoiseMetalParameters &uniforms [[ buffer(0) ]],
        constant const float3 * in                     [[ buffer(1) ]],
        device float * out                             [[ buffer(2) ]],
        constant uint & dataCount                      [[ buffer(3) ]],
        uint2 thread_position_in_grid                  [[ thread_position_in_grid ]],
        uint2 threads_per_grid                         [[ threads_per_grid ]]
    ) {
        uint index = thread_position_in_grid.x;
        
        if (index < dataCount) {
            out[index] = fbm3Warp(uniforms, in[index]);
        }
    }

"""

    static var metalFunctionWithNormal: String? = nil

    static var functionWithNormalName: String? = nil

    static var baseFunction: String =
"""
    #ifndef FBM_NOISE3_BASE
    #define FBM_NOISE3_BASE(OCTAVE_INDEX) \
        if (OCTAVE_INDEX < octaves) { \
            float3 scaledCoord = noiseCoord * frequency; \
            fractalNoise *= (1 / (amplitude + 1)); \
            fractalNoise += amplitude * openSimplexFunction( \
                seed, \
                scaledCoord.x, \
                scaledCoord.y, \
                scaledCoord.z); \
            frequency *= lacunarity; \
            amplitude *= gain; \
        };
    #endif

    float fbm3Base(
        FractalNoiseMetalParameters uniforms,
        float3 inCoord
    ) {
        float amplitude = uniforms.startingAmplitude;
        float frequency = uniforms.startingFrequency;
        float gain = uniforms.gain;
        float lacunarity = uniforms.lacunarity;

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

        int octaves = uniforms.octaves;

        float3 noiseCoord = inCoord;
        float fractalNoise = 0;

        FNOISE_REPEAT(8, FBM_NOISE3_BASE)

        return min(max(fractalNoise, -1.f), 1.f);
    }

    #ifndef FBM_NOISE3_WARP
    #define FBM_NOISE3_WARP(ITERATION_INDEX) \
        if (ITERATION_INDEX < warpIterations) { \
            fractalNoise = fbm3Base(uniforms, noiseCoord + fractalNoise * warpScale); \
        };
    #endif

    float fbm3Warp(
        FractalNoiseMetalParameters uniforms,
        float3 inCoord
    ) {
        int warpIterations = uniforms.warpIterations;
        float warpScale = uniforms.warpScale;
        float3 noiseCoord = inCoord * uniforms.coordinateScale;
        float fractalNoise = 0;

        FNOISE_REPEAT(6, FBM_NOISE3_WARP)

        return fractalNoise;
    }


"""
}

