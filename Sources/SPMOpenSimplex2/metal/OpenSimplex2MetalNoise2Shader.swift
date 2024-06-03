public class OpenSimplex2MetalNoise2: OpenSimplex2MetalNoiseShader {
    static func getVariableMap() -> [String: String] {
        let N_GRADS_2D_EXPONENT = 7
        let N_GRADS_2D = 1 << N_GRADS_2D_EXPONENT
        let NORMALIZER_2D = 0.01001634121365712
        let grad2 = [
            0.38268343236509,   0.923879532511287,
            0.923879532511287,  0.38268343236509,
            0.923879532511287, -0.38268343236509,
            0.38268343236509,  -0.923879532511287,
            -0.38268343236509,  -0.923879532511287,
            -0.923879532511287, -0.38268343236509,
            -0.923879532511287,  0.38268343236509,
            -0.38268343236509,   0.923879532511287,
            //-------------------------------------//
            0.130526192220052,  0.99144486137381,
            0.608761429008721,  0.793353340291235,
            0.793353340291235,  0.608761429008721,
            0.99144486137381,   0.130526192220051,
            0.99144486137381,  -0.130526192220051,
            0.793353340291235, -0.60876142900872,
            0.608761429008721, -0.793353340291235,
            0.130526192220052, -0.99144486137381,
            -0.130526192220052, -0.99144486137381,
            -0.608761429008721, -0.793353340291235,
            -0.793353340291235, -0.608761429008721,
            -0.99144486137381,  -0.130526192220052,
            -0.99144486137381,   0.130526192220051,
            -0.793353340291235,  0.608761429008721,
            -0.608761429008721,  0.793353340291235,
            -0.130526192220052,  0.99144486137381,
        ].map { Float($0 / NORMALIZER_2D) }

        var GRADIENTS_2D = Array<Float>(repeating: 0, count: N_GRADS_2D * 2)

        var j = 0
        for i in 0..<GRADIENTS_2D.count {
            if j == grad2.count {
                j = 0
            }
            GRADIENTS_2D[i] = grad2[j];
            j += 1
        }

        return [
            "N_GRADS_2D": String(N_GRADS_2D),
            "N_GRADS_2D_EXPONENT": String(N_GRADS_2D_EXPONENT),
            "GRADIENTS_2D": "{ \(GRADIENTS_2D.map { formatDouble(Double($0)) }.joined(separator: ", ")) }",
        ]
    }

    static var functionName: String = "openSimplexNoise2"

    static var metalFunction: String =
"""
    kernel void \(functionName)(
        constant OpenSimplex2MetalParameters &uniforms [[ buffer(0) ]],
        constant const float2 * in                     [[ buffer(1) ]],
        device float * out                             [[ buffer(2) ]],
        uint2 thread_position_in_grid                  [[ thread_position_in_grid ]]
    ) {
        int index = thread_position_in_grid.x;
        switch (uniforms.noise2Variant) {
            case OpenSimplex2MetalNoise2Variant::standard:
                out[index] = noise2(uniforms.seed, in[index].x, in[index].y);
                break;
            case OpenSimplex2MetalNoise2Variant::x:
                out[index] = noise2_ImproveX(uniforms.seed, in[index].x, in[index].y);
                break;
        }
    }

"""

    static var metalFunctionWithNormal: String? = nil

    static var functionWithNormalName: String? = nil

    static var baseFunction: String =
"""
    constant static float const ROOT2OVER2 = 0.7071067811865476;
    constant static float const SKEW_2D = 0.366025403784439;
    constant static int const N_GRADS_2D_EXPONENT = ${N_GRADS_2D_EXPONENT};
    constant static int const N_GRADS_2D = ${N_GRADS_2D};
    constant static float const RSQUARED_2D = 0.5f;
    constant static float GRADIENTS_2D[N_GRADS_2D * 2] = ${GRADIENTS_2D};

    float grad(long seed, long xsvp, long ysvp, float dx, float dy) {
        long hash = seed ^ xsvp ^ ysvp;
        hash *= HASH_MULTIPLIER;
        hash ^= hash >> (64 - N_GRADS_2D_EXPONENT + 1);
        int gi = (int)hash & ((N_GRADS_2D - 1) << 1);
        return GRADIENTS_2D[gi | 0] * dx + GRADIENTS_2D[gi | 1] * dy;
    }

    float noise2_UnskewedBase(long seed, float xs, float ys) {
        // Get base points and offsets.
        int xsb = fastFloor(xs), ysb = fastFloor(ys);
        float xi = (float)(xs - xsb), yi = (float)(ys - ysb);

        // Prime pre-multiplication for hash.
        long xsbp = xsb * PRIME_X, ysbp = ysb * PRIME_Y;

        // Unskew.
        float t = (xi + yi) * (float)UNSKEW_2D;
        float dx0 = xi + t, dy0 = yi + t;

        // First vertex.
        float value = 0;
        float a0 = RSQUARED_2D - dx0 * dx0 - dy0 * dy0;
        if (a0 > 0) {
            value = (a0 * a0) * (a0 * a0) * grad(seed, xsbp, ysbp, dx0, dy0);
        }

        // Second vertex.
        float a1 = (float)(2 * (1 + 2 * UNSKEW_2D) * (1 / UNSKEW_2D + 2)) * t + ((float)(-2 * (1 + 2 * UNSKEW_2D) * (1 + 2 * UNSKEW_2D)) + a0);
        if (a1 > 0) {
            float dx1 = dx0 - (float)(1 + 2 * UNSKEW_2D);
            float dy1 = dy0 - (float)(1 + 2 * UNSKEW_2D);
            value += (a1 * a1) * (a1 * a1) * grad(seed, (xsbp + PRIME_X), (ysbp + PRIME_Y), dx1, dy1);
        }

        // Third vertex.
        if (dy0 > dx0) {
            float dx2 = dx0 - (float)UNSKEW_2D;
            float dy2 = dy0 - (float)(UNSKEW_2D + 1);
            float a2 = RSQUARED_2D - dx2 * dx2 - dy2 * dy2;
            if (a2 > 0) {
                value += (a2 * a2) * (a2 * a2) * grad(seed, xsbp, (ysbp + PRIME_Y), dx2, dy2);
            }
        }
        else
        {
            float dx2 = dx0 - (float)(UNSKEW_2D + 1);
            float dy2 = dy0 - (float)UNSKEW_2D;
            float a2 = RSQUARED_2D - dx2 * dx2 - dy2 * dy2;
            if (a2 > 0) {
                value += (a2 * a2) * (a2 * a2) * grad(seed, (xsbp + PRIME_X), ysbp, dx2, dy2);
            }
        }

        return value;
    }

    float noise2(long seed, float x, float y) {
        // Get points for A2* lattice
        float s = SKEW_2D * (x + y);
        float xs = x + s, ys = y + s;

        return noise2_UnskewedBase(seed, xs, ys);
    }

    float noise2_ImproveX(long seed, float x, float y) {
        // Skew transform and rotation baked into one.
        float xx = x * ROOT2OVER2;
        float yy = y * (ROOT2OVER2 * (1 + 2 * SKEW_2D));

        return noise2_UnskewedBase(seed, yy + xx, yy - xx);
    }

"""
}

