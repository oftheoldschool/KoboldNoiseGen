public class OpenSimplex2MetalNoise3: OpenSimplex2MetalNoiseShader {
    static func getVariableMap() -> [String: String] {
        let N_GRADS_3D_EXPONENT = 8
        let N_GRADS_3D = 1 << N_GRADS_3D_EXPONENT
        let NORMALIZER_3D = 0.07969837668935331
        let grad3 = [
            2.22474487139,       2.22474487139,      -1.0,                 0.0,
            2.22474487139,       2.22474487139,       1.0,                 0.0,
            3.0862664687972017,  1.1721513422464978,  0.0,                 0.0,
            1.1721513422464978,  3.0862664687972017,  0.0,                 0.0,
            -2.22474487139,       2.22474487139,      -1.0,                 0.0,
            -2.22474487139,       2.22474487139,       1.0,                 0.0,
            -1.1721513422464978,  3.0862664687972017,  0.0,                 0.0,
            -3.0862664687972017,  1.1721513422464978,  0.0,                 0.0,
            -1.0,                -2.22474487139,      -2.22474487139,       0.0,
            1.0,                -2.22474487139,      -2.22474487139,       0.0,
            0.0,                -3.0862664687972017, -1.1721513422464978,  0.0,
            0.0,                -1.1721513422464978, -3.0862664687972017,  0.0,
            -1.0,                -2.22474487139,       2.22474487139,       0.0,
            1.0,                -2.22474487139,       2.22474487139,       0.0,
            0.0,                -1.1721513422464978,  3.0862664687972017,  0.0,
            0.0,                -3.0862664687972017,  1.1721513422464978,  0.0,
            //--------------------------------------------------------------------//
            -2.22474487139,      -2.22474487139,      -1.0,                 0.0,
            -2.22474487139,      -2.22474487139,       1.0,                 0.0,
            -3.0862664687972017, -1.1721513422464978,  0.0,                 0.0,
            -1.1721513422464978, -3.0862664687972017,  0.0,                 0.0,
            -2.22474487139,      -1.0,                -2.22474487139,       0.0,
            -2.22474487139,       1.0,                -2.22474487139,       0.0,
            -1.1721513422464978,  0.0,                -3.0862664687972017,  0.0,
            -3.0862664687972017,  0.0,                -1.1721513422464978,  0.0,
            -2.22474487139,      -1.0,                 2.22474487139,       0.0,
            -2.22474487139,       1.0,                 2.22474487139,       0.0,
            -3.0862664687972017,  0.0,                 1.1721513422464978,  0.0,
            -1.1721513422464978,  0.0,                 3.0862664687972017,  0.0,
            -1.0,                 2.22474487139,      -2.22474487139,       0.0,
            1.0,                 2.22474487139,      -2.22474487139,       0.0,
            0.0,                 1.1721513422464978, -3.0862664687972017,  0.0,
            0.0,                 3.0862664687972017, -1.1721513422464978,  0.0,
            -1.0,                 2.22474487139,       2.22474487139,       0.0,
            1.0,                 2.22474487139,       2.22474487139,       0.0,
            0.0,                 3.0862664687972017,  1.1721513422464978,  0.0,
            0.0,                 1.1721513422464978,  3.0862664687972017,  0.0,
            2.22474487139,      -2.22474487139,      -1.0,                 0.0,
            2.22474487139,      -2.22474487139,       1.0,                 0.0,
            1.1721513422464978, -3.0862664687972017,  0.0,                 0.0,
            3.0862664687972017, -1.1721513422464978,  0.0,                 0.0,
            2.22474487139,      -1.0,                -2.22474487139,       0.0,
            2.22474487139,       1.0,                -2.22474487139,       0.0,
            3.0862664687972017,  0.0,                -1.1721513422464978,  0.0,
            1.1721513422464978,  0.0,                -3.0862664687972017,  0.0,
            2.22474487139,      -1.0,                 2.22474487139,       0.0,
            2.22474487139,       1.0,                 2.22474487139,       0.0,
            1.1721513422464978,  0.0,                 3.0862664687972017,  0.0,
            3.0862664687972017,  0.0,                 1.1721513422464978,  0.0,
        ].map { Float($0 / NORMALIZER_3D) }
        var GRADIENTS_3D = Array<Float>.init(repeating: 0, count: N_GRADS_3D * 4)

        var j = 0
        for i in 0..<GRADIENTS_3D.count {
            if j == grad3.count {
                j = 0
            }
            GRADIENTS_3D[i] = grad3[j];
            j += 1
        }

        return [
            "N_GRADS_3D": String(N_GRADS_3D),
            "N_GRADS_3D_EXPONENT": String(N_GRADS_3D_EXPONENT),
            "GRADIENTS_3D": "{ \(GRADIENTS_3D.map { formatDouble(Double($0)) }.joined(separator: ", ")) }",
        ]
    }

    static var functionName: String = "openSimplexNoise3"

    static var metalFunction: String =
"""
    kernel void \(functionName)(
        constant OpenSimplex2MetalParameters &uniforms [[ buffer(0) ]],
        constant const float3 * in                     [[ buffer(1) ]],
        device float * out                             [[ buffer(2) ]],
        uint2 thread_position_in_grid                  [[ thread_position_in_grid ]]
    ) {
        int index = thread_position_in_grid.x;
        switch (uniforms.noise3Variant) {
            case OpenSimplex2MetalNoise3Variant::xy:
                out[index] = noise3_ImproveXY(uniforms.seed, in[index].x, in[index].y, in[index].z);
                break;
            case OpenSimplex2MetalNoise3Variant::xz:
                out[index] = noise3_ImproveXZ(uniforms.seed, in[index].x, in[index].y, in[index].z);
                break;
            case OpenSimplex2MetalNoise3Variant::fallback:
                out[index] = noise3_Fallback(uniforms.seed, in[index].x, in[index].y, in[index].z);
                break;
        }
    }
"""

    static var baseFunction: String =
"""
    constant static int const N_GRADS_3D_EXPONENT = ${N_GRADS_3D_EXPONENT};
    constant static int const N_GRADS_3D = ${N_GRADS_3D};
    constant static float GRADIENTS_3D[N_GRADS_3D * 4] = ${GRADIENTS_3D};
    constant static float const RSQUARED_3D = 0.6f;
    constant static long const SEED_FLIP_3D = -0x52D547B2E96ED629L;
    constant static float const ROTATE_3D_ORTHOGONALIZER = UNSKEW_2D;
    constant static float const ROOT3OVER3 = 0.577350269189626;
    constant static float const FALLBACK_ROTATE_3D = 2.0 / 3.0;

    float grad(long seed, long xrvp, long yrvp, long zrvp, float dx, float dy, float dz) {
        long hash = (seed ^ xrvp) ^ (yrvp ^ zrvp);
        hash *= HASH_MULTIPLIER;
        hash ^= hash >> (64 - N_GRADS_3D_EXPONENT + 2);
        int gi = (int)hash & ((N_GRADS_3D - 1) << 2);
        return GRADIENTS_3D[gi | 0] * dx + GRADIENTS_3D[gi | 1] * dy + GRADIENTS_3D[gi | 2] * dz;
    }

    float noise3_UnrotatedBase(long seed, float xr, float yr, float zr) {

        // Get base points and offsets.
        int xrb = fastRound(xr), yrb = fastRound(yr), zrb = fastRound(zr);
        float xri = (float)(xr - xrb), yri = (float)(yr - yrb), zri = (float)(zr - zrb);

        // -1 if positive, 1 if negative.
        int xNSign = (int)(-1.0f - xri) | 1, yNSign = (int)(-1.0f - yri) | 1, zNSign = (int)(-1.0f - zri) | 1;

        // Compute absolute values, using the above as a shortcut. This was faster in my tests for some reason.
        float ax0 = xNSign * -xri, ay0 = yNSign * -yri, az0 = zNSign * -zri;

        // Prime pre-multiplication for hash.
        long xrbp = xrb * PRIME_X, yrbp = yrb * PRIME_Y, zrbp = zrb * PRIME_Z;

        // Loop: Pick an edge on each lattice copy.
        float value = 0;
        float a = (RSQUARED_3D - xri * xri) - (yri * yri + zri * zri);
        for (int l = 0; ; l++) {

            // Closest point on cube.
            if (a > 0) {
                value += (a * a) * (a * a) * grad(seed, xrbp, yrbp, zrbp, xri, yri, zri);
            }

            // Second-closest point.
            if (ax0 >= ay0 && ax0 >= az0) {
                float b = a + ax0 + ax0;
                if (b > 1) {
                    b -= 1;
                    value += (b * b) * (b * b) * grad(seed, xrbp - xNSign * PRIME_X, yrbp, zrbp, xri + xNSign, yri, zri);
                }
            }
            else if (ay0 > ax0 && ay0 >= az0) {
                float b = a + ay0 + ay0;
                if (b > 1) {
                    b -= 1;
                    value += (b * b) * (b * b) * grad(seed, xrbp, yrbp - yNSign * PRIME_Y, zrbp, xri, yri + yNSign, zri);
                }
            }
            else
            {
                float b = a + az0 + az0;
                if (b > 1) {
                    b -= 1;
                    value += (b * b) * (b * b) * grad(seed, xrbp, yrbp, zrbp - zNSign * PRIME_Z, xri, yri, zri + zNSign);
                }
            }

            // Break from loop if we're done, skipping updates below.
            if (l == 1) break;

            // Update absolute value.
            ax0 = 0.5f - ax0;
            ay0 = 0.5f - ay0;
            az0 = 0.5f - az0;

            // Update relative coordinate.
            xri = xNSign * ax0;
            yri = yNSign * ay0;
            zri = zNSign * az0;

            // Update falloff.
            a += (0.75f - ax0) - (ay0 + az0);

            // Update prime for hash.
            xrbp += (xNSign >> 1) & PRIME_X;
            yrbp += (yNSign >> 1) & PRIME_Y;
            zrbp += (zNSign >> 1) & PRIME_Z;

            // Update the reverse sign indicators.
            xNSign = -xNSign;
            yNSign = -yNSign;
            zNSign = -zNSign;

            // And finally update the seed for the other lattice copy.
            seed ^= SEED_FLIP_3D;
        }

        return value;
    }

    float noise3_ImproveXY(long seed, float x, float y, float z) {
        float xy = x + y;
        float s2 = xy * ROTATE_3D_ORTHOGONALIZER;
        float zz = z * ROOT3OVER3;
        float xr = x + s2 + zz;
        float yr = y + s2 + zz;
        float zr = xy * -ROOT3OVER3 + zz;

        // Evaluate both lattices to form a BCC lattice.
        return noise3_UnrotatedBase(seed, xr, yr, zr);
    }

    float noise3_ImproveXZ(long seed, float x, float y, float z) {

        // Re-orient the cubic lattices without skewing, so Y points up the main lattice diagonal,
        // and the planes formed by XZ are moved far out of alignment with the cube faces.
        // Orthonormal rotation. Not a skew transform.
        float xz = x + z;
        float s2 = xz * ROTATE_3D_ORTHOGONALIZER;
        float yy = y * ROOT3OVER3;
        float xr = x + s2 + yy;
        float zr = z + s2 + yy;
        float yr = xz * -ROOT3OVER3 + yy;

        // Evaluate both lattices to form a BCC lattice.
        return noise3_UnrotatedBase(seed, xr, yr, zr);
    }

    float noise3_Fallback(long seed, float x, float y, float z) {
        float r = FALLBACK_ROTATE_3D * (x + y + z);
        float xr = r - x, yr = r - y, zr = r - z;

        // Evaluate both lattices to form a BCC lattice.
        return noise3_UnrotatedBase(seed, xr, yr, zr);
    }


"""
}

