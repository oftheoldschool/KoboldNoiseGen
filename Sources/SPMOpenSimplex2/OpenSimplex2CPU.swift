// OpenSimplex2(F) translated from Java implementation at https://github.com/KdotJPG/OpenSimplex2
public class OpenSimplex2CPU {
    private static var PRIME_X: Int { 0x5205402B9270C86F }
    private static var PRIME_Y: Int { 0x598CD327003817B5 }
    private static var PRIME_Z: Int { 0x5BCC226E9FA0BACB }
    private static var PRIME_W: Int { 0x56CC5227E58F554B }
    private static var HASH_MULTIPLIER: Int { 0x53A3F72DEEC546F5 }
    private static var SEED_FLIP_3D: Int { -0x52D547B2E96ED629 }
    private static var SEED_OFFSET_4D: Int { 0xE83DC3E0DA7164D }

    private static var ROOT2OVER2: Double { 0.7071067811865476 }
    private static var SKEW_2D: Double { 0.366025403784439 }
    private static var UNSKEW_2D: Double { -0.21132486540518713 }

    private static var ROOT3OVER3: Double { 0.577350269189626 }
    private static var FALLBACK_ROTATE_3D: Double { 2.0 / 3.0 }
    private static var ROTATE_3D_ORTHOGONALIZER: Double { UNSKEW_2D }

    private static var SKEW_4D: Float { -0.138196601125011 }
    private static var UNSKEW_4D: Float { 0.309016994374947 }
    private static var LATTICE_STEP_4D: Float { 0.2 }

    private static var N_GRADS_2D_EXPONENT: Int { 7 }
    private static var N_GRADS_3D_EXPONENT: Int { 8 }
    private static var N_GRADS_4D_EXPONENT: Int { 9 }
    private static var N_GRADS_2D: Int { 1 << N_GRADS_2D_EXPONENT }
    private static var N_GRADS_3D: Int { 1 << N_GRADS_3D_EXPONENT }
    private static var N_GRADS_4D: Int { 1 << N_GRADS_4D_EXPONENT }

    private static var NORMALIZER_2D: Double { 0.01001634121365712 }
    private static var NORMALIZER_3D: Double { 0.07969837668935331 }
    private static var NORMALIZER_4D: Double { 0.0220065933241897 }

    private static var RSQUARED_2D: Float { 0.5 }
    private static var RSQUARED_3D: Float { 0.6 }
    private static var RSQUARED_4D: Float { 0.6 }

    public init() {

    }

    private func noise2_Standard(seed: Int, x: Double, y: Double) -> Float {
        let s = Self.SKEW_2D * (x + y)
        let xs = x + s
        let ys = y + s
        return noise2_UnskewedBase(seed, xs, ys)
    }

    private func noise2_ImproveX(seed: Int, x: Double, y: Double) -> Float {
        let xx = x * Self.ROOT2OVER2
        let yy = y * (Self.ROOT2OVER2 * (1 + 2 * Self.SKEW_2D))
        return noise2_UnskewedBase(seed, yy + xx, yy - xx)
    }

    private func noise2_UnskewedBase(_ seed: Int, _ xs: Double, _ ys: Double) -> Float {
        let xsb = fastFloor(xs)
        let ysb = fastFloor(ys)
        let xi = Float(xs) - Float(xsb)
        let yi = Float(ys) - Float(ysb)

        let xsbp = xsb &* Self.PRIME_X
        let ysbp = ysb &* Self.PRIME_Y

        let t = (xi + yi) * Float(Self.UNSKEW_2D)
        let dx0 = xi + t
        let dy0 = yi + t

        var value: Float = 0
        let a0 = Self.RSQUARED_2D - dx0 * dx0 - dy0 * dy0
        if a0 > 0 {
            value = (a0 * a0) * (a0 * a0) * grad(seed: seed, xsvp: xsbp, ysvp: ysbp, dx: dx0, dy: dy0)
        }

        let xsvp = xsbp &+ Self.PRIME_X
        let ysvp = ysbp &+ Self.PRIME_Y

        let a1 = Float(2 * (1 + 2 * Self.UNSKEW_2D) * (1 / Self.UNSKEW_2D + 2)) * t + (Float(-2 * (1 + 2 * Self.UNSKEW_2D) * (1 + 2 * Self.UNSKEW_2D)) + a0)
        if a1 > 0 {
            let dx1 = dx0 - Float(1 + 2 * Self.UNSKEW_2D)
            let dy1 = dy0 - Float(1 + 2 * Self.UNSKEW_2D)
            value += (a1 * a1) * (a1 * a1) * grad(
                seed: seed,
                xsvp: xsvp,
                ysvp: ysvp,
                dx: dx1,
                dy: dy1)
        }

        if dy0 > dx0 {
            let dx2 = dx0 - Float(Self.UNSKEW_2D)
            let dy2 = dy0 - Float(Self.UNSKEW_2D + 1)
            let a2 = Self.RSQUARED_2D - dx2 * dx2 - dy2 * dy2
            if a2 > 0 {
                value += (a2 * a2) * (a2 * a2) * grad(
                    seed: seed,
                    xsvp: xsbp,
                    ysvp: ysvp,
                    dx: dx2,
                    dy: dy2)
            }
        } else {
            let dx2 = dx0 - Float(Self.UNSKEW_2D + 1)
            let dy2 = dy0 - Float(Self.UNSKEW_2D)
            let a2 = Self.RSQUARED_2D - dx2 * dx2 - dy2 * dy2
            if a2 > 0 {
                value += (a2 * a2) * (a2 * a2) * grad(
                    seed: seed,
                    xsvp: xsvp,
                    ysvp: ysbp,
                    dx: dx2,
                    dy: dy2)
            }
        }

        return value
    }

    private func noise3_ImproveXY(seed: Int, x: Double, y: Double, z: Double) -> Float {
        let xy = x + y
        let s2 = xy * Self.ROTATE_3D_ORTHOGONALIZER
        let zz = z * Self.ROOT3OVER3
        let xr = x + s2 + zz
        let yr = y + s2 + zz
        let zr = xy * -Self.ROOT3OVER3 + zz

        return noise3_UnrotatedBase(seed: seed, xr: xr, yr: yr, zr: zr)
    }

    private func noise3_ImproveXZ(seed: Int, x: Double, y: Double, z: Double) -> Float {
        let xz = x + z;
        let s2 = xz * Self.ROTATE_3D_ORTHOGONALIZER
        let yy = y * Self.ROOT3OVER3
        let xr = x + s2 + yy
        let zr = z + s2 + yy
        let yr = xz * -Self.ROOT3OVER3 + yy

        return noise3_UnrotatedBase(seed: seed, xr: xr, yr: yr, zr: zr)
    }

    private func noise3_Fallback(seed: Int, x: Double, y: Double, z: Double) -> Float{
        let r = Self.FALLBACK_ROTATE_3D * (x + y + z)
        let xr = r - x
        let yr = r - y
        let zr = r - z

        return noise3_UnrotatedBase(seed: seed, xr: xr, yr: yr, zr: zr)
    }

    private func noise3_UnrotatedBase(seed: Int, xr: Double, yr: Double, zr: Double) -> Float {
        var mutableSeed = seed
        let xrb = fastRound(xr)
        let yrb = fastRound(yr)
        let zrb = fastRound(zr)
        var xri = Float(xr) - Float(xrb)
        var yri = Float(yr) - Float(yrb)
        var zri = Float(zr) - Float(zrb)

        // -1 if positive, 1 if negative.
        var xNSign = Int(-1.0 - xri) | 1
        var yNSign = Int(-1.0 - yri) | 1
        var zNSign = Int(-1.0 - zri) | 1

        // Compute absolute values, using the above as a shortcut. This was faster in my tests for some reason.
        var ax0 = Float(xNSign) * -xri
        var ay0 = Float(yNSign) * -yri
        var az0 = Float(zNSign) * -zri

        // Prime pre-multiplication for hash.
        var xrbp = xrb &* Self.PRIME_X
        var yrbp = yrb &* Self.PRIME_Y
        var zrbp = zrb &* Self.PRIME_Z

        // Loop: Pick an edge on each lattice copy.
        var value: Float = 0
        var a = (Self.RSQUARED_3D - xri * xri) - (yri * yri + zri * zri)

        var l: Int = 0
        while true {
            // Closest point on cube.
            if a > 0 {
                value += (a * a) * (a * a) * grad(
                    seed: mutableSeed,
                    xrvp: xrbp,
                    yrvp: yrbp,
                    zrvp: zrbp,
                    dx: xri,
                    dy: yri,
                    dz: zri)
            }

            // Second-closest point.
            if ax0 >= ay0 && ax0 >= az0 {
                var b = a + ax0 + ax0
                if b > 1 {
                    b -= 1
                    value += (b * b) * (b * b) * grad(
                        seed: mutableSeed,
                        xrvp: xrbp &- (xNSign * Self.PRIME_X),
                        yrvp: yrbp,
                        zrvp: zrbp,
                        dx: xri + Float(xNSign),
                        dy: yri,
                        dz: zri)
                }
            } else if ay0 > ax0 && ay0 >= az0 {
                var b = a + ay0 + ay0
                if b > 1 {
                    b -= 1
                    value += (b * b) * (b * b) * grad(
                        seed: mutableSeed,
                        xrvp: xrbp,
                        yrvp: yrbp &- (yNSign * Self.PRIME_Y),
                        zrvp: zrbp,
                        dx: xri,
                        dy: yri + Float(yNSign),
                        dz: zri)
                }
            } else {
                var b = a + az0 + az0
                if b > 1 {
                    b -= 1
                    value += (b * b) * (b * b) * grad(
                        seed: mutableSeed,
                        xrvp: xrbp,
                        yrvp: yrbp,
                        zrvp: zrbp &- (zNSign * Self.PRIME_Z),
                        dx: xri,
                        dy: yri,
                        dz: zri + Float(zNSign))
                }
            }

            if l == 1 {
                break
            }

            // Update absolute value.
            ax0 = 0.5 - ax0
            ay0 = 0.5 - ay0
            az0 = 0.5 - az0

            // Update relative coordinate.
            xri = Float(xNSign) * ax0
            yri = Float(yNSign) * ay0
            zri = Float(zNSign) * az0

            // Update falloff.
            a += (0.75 - ax0) - (ay0 + az0)

            // Update prime for hash.
            xrbp &+= ((xNSign >> 1) & Self.PRIME_X)
            yrbp &+= ((yNSign >> 1) & Self.PRIME_Y)
            zrbp &+= ((zNSign >> 1) & Self.PRIME_Z)

            // Update the reverse sign indicators.
            xNSign = -xNSign
            yNSign = -yNSign
            zNSign = -zNSign

            // And finally update the seed for the other lattice copy.
            mutableSeed ^= Self.SEED_FLIP_3D

            l += 1
        }

        return value
    }


    private func noise4_ImproveXYZ_ImproveXY(seed: Int, x: Double, y: Double, z: Double, w: Double) -> Float {
        let xy = x + y
        let s2 = xy * -0.21132486540518699998
        let zz = z * 0.28867513459481294226
        let ww = w * 0.2236067977499788
        let xr = x + (zz + ww + s2), yr = y + (zz + ww + s2)
        let zr = xy * -0.57735026918962599998 + (zz + ww)
        let wr = z * -0.866025403784439 + ww

        return noise4_UnskewedBase(seed: seed, xs: xr, ys: yr, zs: zr, ws: wr)
    }

    /**
     * 4D OpenSimplex2 noise, with XYZ oriented like noise3_ImproveXZ
     * and W for an extra degree of freedom. W repeats eventually.
     * Recommended for time-varied animations which texture a 3D object (W=time)
     * in a space where Y is vertical
     */
    private func noise4_ImproveXYZ_ImproveXZ(seed: Int, x: Double, y: Double, z: Double, w: Double) -> Float {
        let xz = x + z
        let s2 = xz * -0.21132486540518699998
        let yy = y * 0.28867513459481294226
        let ww = w * 0.2236067977499788
        let xr = x + (yy + ww + s2), zr = z + (yy + ww + s2)
        let yr = xz * -0.57735026918962599998 + (yy + ww)
        let wr = y * -0.866025403784439 + ww

        return noise4_UnskewedBase(seed: seed, xs: xr, ys: yr, zs: zr, ws: wr)
    }

    /**
     * 4D OpenSimplex2 noise, with XYZ oriented like noise3_Fallback
     * and W for an extra degree of freedom. W repeats eventually.
     * Recommended for time-varied animations which texture a 3D object (W=time)
     * where there isn't a clear distinction between horizontal and vertical
     */
    private func noise4_ImproveXYZ(seed: Int, x: Double, y: Double, z: Double, w: Double) -> Float {
        let xyz = x + y + z
        let ww = w * 0.2236067977499788
        let s2 = xyz * -0.16666666666666666 + ww
        let xs = x + s2, ys = y + s2, zs = z + s2, ws = -0.5 * xyz + ww

        return noise4_UnskewedBase(seed: seed, xs: xs, ys: ys, zs: zs, ws: ws)
    }

    /**
     * 4D OpenSimplex2 noise, with XY and ZW forming orthogonal triangular-based planes.
     * Recommended for 3D terrain, where X and Y (or Z and W) are horizontal.
     * Recommended for noise(x, y, sin(time), cos(time)) trick.
     */
    private func noise4_ImproveXY_ImproveZW(seed: Int, x: Double, y: Double, z: Double, w: Double) -> Float {
        let s2 = (x + y) * -0.178275657951399372 + (z + w) * 0.215623393288842828
        let t2 = (z + w) * -0.403949762580207112 + (x + y) * -0.375199083010075342
        let xs = x + s2, ys = y + s2, zs = z + t2, ws = w + t2

        return noise4_UnskewedBase(seed: seed, xs: xs, ys: ys, zs: zs, ws: ws)
    }

    /**
     * 4D OpenSimplex2 noise, fallback lattice orientation.
     */
    private func noise4_Fallback(seed: Int, x: Double, y: Double, z: Double, w: Double) -> Float {
        // Get points for A4 lattice
        let s = Double(Self.SKEW_4D) * (x + y + z + w)
        let xs = x + s, ys = y + s, zs = z + s, ws = w + s

        return noise4_UnskewedBase(seed: seed, xs: xs, ys: ys, zs: zs, ws: ws);
    }


    private func noise4_UnskewedBase(seed: Int, xs: Double, ys: Double, zs: Double, ws: Double) -> Float {
        var mutableSeed = seed

        // Get base points and offsets
        let xsb = fastFloor(xs)
        let ysb = fastFloor(ys)
        let zsb = fastFloor(zs)
        let wsb = fastFloor(ws)
        var xsi = Float(xs - Double(xsb))
        var ysi = Float(ys - Double(ysb))
        var zsi = Float(zs - Double(zsb))
        var wsi = Float(ws - Double(wsb))

        // Determine which lattice we can be confident has a contributing point its corresponding cell's base simplex.
        // We only look at the spaces between the diagonal planes. This proved effective in all of my tests.
        let siSum = (xsi + ysi) + (zsi + wsi)
        let startingLattice = Int(siSum * 1.25)

        // Offset for seed based on first lattice copy.
        mutableSeed += startingLattice * Self.SEED_OFFSET_4D

        // Offset for lattice point relative positions (skewed)
        let startingLatticeOffset = Float(startingLattice) * -Self.LATTICE_STEP_4D
        xsi += startingLatticeOffset
        ysi += startingLatticeOffset
        zsi += startingLatticeOffset
        wsi += startingLatticeOffset

        // Prep for vertex contributions.
        var ssi = (siSum + startingLatticeOffset * 4) * Self.UNSKEW_4D;

        // Prime pre-multiplication for hash.
        var xsvp = xsb &* Self.PRIME_X
        var ysvp = ysb &* Self.PRIME_Y
        var zsvp = zsb &* Self.PRIME_Z
        var wsvp = wsb &* Self.PRIME_W

        // Five points to add, total, from five copies of the A4 lattice.
        var value: Float = 0
        var i: Int = 0

        while true {
            // Next point is the closest vertex on the 4-simplex whose base vertex is the aforementioned vertex.
            let score0 = 1.0 + ssi * (-1.0 / Self.UNSKEW_4D) // Seems slightly faster than 1.0-xsi-ysi-zsi-wsi
            if (xsi >= ysi && xsi >= zsi && xsi >= wsi && xsi >= score0) {
                xsvp &+= Self.PRIME_X
                xsi -= 1
                ssi -= Self.UNSKEW_4D
            } else if (ysi > xsi && ysi >= zsi && ysi >= wsi && ysi >= score0) {
                ysvp &+= Self.PRIME_Y
                ysi -= 1
                ssi -= Self.UNSKEW_4D
            } else if (zsi > xsi && zsi > ysi && zsi >= wsi && zsi >= score0) {
                zsvp &+= Self.PRIME_Z
                zsi -= 1
                ssi -= Self.UNSKEW_4D
            } else if (wsi > xsi && wsi > ysi && wsi > zsi && wsi >= score0) {
                wsvp &+= Self.PRIME_W
                wsi -= 1
                ssi -= Self.UNSKEW_4D
            }

            // gradient contribution with falloff.
            let dx = xsi + ssi, dy = ysi + ssi, dz = zsi + ssi, dw = wsi + ssi
            var a = (dx * dx + dy * dy) + (dz * dz + dw * dw)
            if (a < Self.RSQUARED_4D) {
                a -= Self.RSQUARED_4D
                a *= a
                value += a * a * grad(
                    seed: mutableSeed,
                    xsvp: xsvp,
                    ysvp: ysvp,
                    zsvp: zsvp,
                    wsvp: wsvp,
                    dx: dx,
                    dy: dy,
                    dz: dz,
                    dw: dw)
            }

            // Break from loop if we're done, skipping updates below.
            if (i == 4) {
                break
            }

            // Update for next lattice copy shifted down by <-0.2, -0.2, -0.2, -0.2>.
            xsi += Self.LATTICE_STEP_4D
            ysi += Self.LATTICE_STEP_4D
            zsi += Self.LATTICE_STEP_4D
            wsi += Self.LATTICE_STEP_4D
            ssi += Self.LATTICE_STEP_4D * 4 * Self.UNSKEW_4D
            mutableSeed &-= Self.SEED_OFFSET_4D

            // Because we don't always start on the same lattice copy, there's a special reset case.
            if (i == startingLattice) {
                xsvp &-= Self.PRIME_X
                ysvp &-= Self.PRIME_Y
                zsvp &-= Self.PRIME_Z
                wsvp &-= Self.PRIME_W
                mutableSeed &+= Self.SEED_OFFSET_4D * 5
            }
            i += 1
        }

        return value;
    }

    private func grad(
        seed: Int,
        xsvp: Int, 
        ysvp: Int,
        dx: Float,
        dy: Float
    ) -> Float {
        var hash = seed ^ xsvp ^ ysvp
        hash = hash &* Self.HASH_MULTIPLIER
        hash ^= hash >> (64 - Self.N_GRADS_2D_EXPONENT + 1);
        let gi = Int(hash) & ((Self.N_GRADS_2D - 1) << 1);
        return Self.GRADIENTS_2D[gi | 0] * dx + Self.GRADIENTS_2D[gi | 1] * dy;
    }

    private func grad(
        seed: Int,
        xrvp: Int,
        yrvp: Int,
        zrvp: Int,
        dx: Float,
        dy: Float,
        dz: Float
    ) -> Float {
        var hash = (seed ^ xrvp) ^ (yrvp ^ zrvp)
        hash = hash &* Self.HASH_MULTIPLIER
        hash ^= hash >> (64 - Self.N_GRADS_3D_EXPONENT + 2)
        let gi = Int(hash) & ((Self.N_GRADS_3D - 1) << 2)
        return Self.GRADIENTS_3D[gi | 0] * dx + Self.GRADIENTS_3D[gi | 1] * dy + Self.GRADIENTS_3D[gi | 2] * dz
    }

    private func grad(
        seed: Int,
        xsvp: Int,
        ysvp: Int, 
        zsvp: Int,
        wsvp: Int,
        dx: Float,
        dy: Float,
        dz: Float,
        dw: Float
    ) -> Float {
        var hash = seed ^ (xsvp ^ ysvp) ^ (zsvp ^ wsvp)
        hash = hash &*  Self.HASH_MULTIPLIER
        hash ^= hash >> (64 - Self.N_GRADS_4D_EXPONENT + 2)
        let gi = Int(hash) & ((Self.N_GRADS_4D - 1) << 2)
        return (Self.GRADIENTS_4D[gi | 0] * dx + Self.GRADIENTS_4D[gi | 1] * dy) + (Self.GRADIENTS_4D[gi | 2] * dz + Self.GRADIENTS_4D[gi | 3] * dw)
    }

    private func fastFloor(_ x: Double) -> Int {
        let xi = Int(x)
        return x < Double(xi) ? xi - 1 : xi
    }

    private func fastRound(_ x: Double) -> Int {
        return x < 0 ? Int(x - 0.5) : Int(x + 0.5)
    }

    private static var GRADIENTS_2D: [Float] {
        var GRADIENTS_2D = Array<Float>(repeating: 0, count: Self.N_GRADS_2D * 2)
        var grad2: [Float] = [
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
        ]
        for i in 0..<grad2.count {
            grad2[i] = Float(grad2[i] / Float(Self.NORMALIZER_2D))
        }
        var j = 0
        for i in 0..<GRADIENTS_2D.count {
            if j == grad2.count {
                j = 0
            }
            GRADIENTS_2D[i] = grad2[j]
            j += 1
        }
        return GRADIENTS_2D
    }

    private static var GRADIENTS_3D: [Float] {
        var GRADIENTS_3D = Array<Float>(repeating: 0, count: N_GRADS_3D * 4)
        var grad3: [Float] = [
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
        ]
        for i in 0..<grad3.count {
            grad3[i] = Float(grad3[i] / Float(Self.NORMALIZER_3D))
        }
        var j = 0
        for i in 0..<GRADIENTS_3D.count {
            if j == grad3.count {
                j = 0
            }
            GRADIENTS_3D[i] = grad3[j]
            j += 1
        }
        return GRADIENTS_3D
    }

    private static var GRADIENTS_4D: [Float] {
        var GRADIENTS_4D = Array<Float>(repeating: 0, count: N_GRADS_4D * 4)
        var grad4: [Float] = [
            -0.6740059517812944,   -0.3239847771997537,   -0.3239847771997537,    0.5794684678643381,
             -0.7504883828755602,   -0.4004672082940195,    0.15296486218853164,   0.5029860367700724,
             -0.7504883828755602,    0.15296486218853164,  -0.4004672082940195,    0.5029860367700724,
             -0.8828161875373585,    0.08164729285680945,   0.08164729285680945,   0.4553054119602712,
             -0.4553054119602712,   -0.08164729285680945,  -0.08164729285680945,   0.8828161875373585,
             -0.5029860367700724,   -0.15296486218853164,   0.4004672082940195,    0.7504883828755602,
             -0.5029860367700724,    0.4004672082940195,   -0.15296486218853164,   0.7504883828755602,
             -0.5794684678643381,    0.3239847771997537,    0.3239847771997537,    0.6740059517812944,
             -0.6740059517812944,   -0.3239847771997537,    0.5794684678643381,   -0.3239847771997537,
             -0.7504883828755602,   -0.4004672082940195,    0.5029860367700724,    0.15296486218853164,
             -0.7504883828755602,    0.15296486218853164,   0.5029860367700724,   -0.4004672082940195,
             -0.8828161875373585,    0.08164729285680945,   0.4553054119602712,    0.08164729285680945,
             -0.4553054119602712,   -0.08164729285680945,   0.8828161875373585,   -0.08164729285680945,
             -0.5029860367700724,   -0.15296486218853164,   0.7504883828755602,    0.4004672082940195,
             -0.5029860367700724,    0.4004672082940195,    0.7504883828755602,   -0.15296486218853164,
             -0.5794684678643381,    0.3239847771997537,    0.6740059517812944,    0.3239847771997537,
             -0.6740059517812944,    0.5794684678643381,   -0.3239847771997537,   -0.3239847771997537,
             -0.7504883828755602,    0.5029860367700724,   -0.4004672082940195,    0.15296486218853164,
             -0.7504883828755602,    0.5029860367700724,    0.15296486218853164,  -0.4004672082940195,
             -0.8828161875373585,    0.4553054119602712,    0.08164729285680945,   0.08164729285680945,
             -0.4553054119602712,    0.8828161875373585,   -0.08164729285680945,  -0.08164729285680945,
             -0.5029860367700724,    0.7504883828755602,   -0.15296486218853164,   0.4004672082940195,
             -0.5029860367700724,    0.7504883828755602,    0.4004672082940195,   -0.15296486218853164,
             -0.5794684678643381,    0.6740059517812944,    0.3239847771997537,    0.3239847771997537,
             0.5794684678643381,   -0.6740059517812944,   -0.3239847771997537,   -0.3239847771997537,
             0.5029860367700724,   -0.7504883828755602,   -0.4004672082940195,    0.15296486218853164,
             0.5029860367700724,   -0.7504883828755602,    0.15296486218853164,  -0.4004672082940195,
             0.4553054119602712,   -0.8828161875373585,    0.08164729285680945,   0.08164729285680945,
             0.8828161875373585,   -0.4553054119602712,   -0.08164729285680945,  -0.08164729285680945,
             0.7504883828755602,   -0.5029860367700724,   -0.15296486218853164,   0.4004672082940195,
             0.7504883828755602,   -0.5029860367700724,    0.4004672082940195,   -0.15296486218853164,
             0.6740059517812944,   -0.5794684678643381,    0.3239847771997537,    0.3239847771997537,
             //------------------------------------------------------------------------------------------//
             -0.753341017856078,    -0.37968289875261624,  -0.37968289875261624,  -0.37968289875261624,
             -0.7821684431180708,   -0.4321472685365301,   -0.4321472685365301,    0.12128480194602098,
             -0.7821684431180708,   -0.4321472685365301,    0.12128480194602098,  -0.4321472685365301,
             -0.7821684431180708,    0.12128480194602098,  -0.4321472685365301,   -0.4321472685365301,
             -0.8586508742123365,   -0.508629699630796,     0.044802370851755174,  0.044802370851755174,
             -0.8586508742123365,    0.044802370851755174, -0.508629699630796,     0.044802370851755174,
             -0.8586508742123365,    0.044802370851755174,  0.044802370851755174, -0.508629699630796,
             -0.9982828964265062,   -0.03381941603233842,  -0.03381941603233842,  -0.03381941603233842,
             -0.37968289875261624,  -0.753341017856078,    -0.37968289875261624,  -0.37968289875261624,
             -0.4321472685365301,   -0.7821684431180708,   -0.4321472685365301,    0.12128480194602098,
             -0.4321472685365301,   -0.7821684431180708,    0.12128480194602098,  -0.4321472685365301,
             0.12128480194602098,  -0.7821684431180708,   -0.4321472685365301,   -0.4321472685365301,
             -0.508629699630796,    -0.8586508742123365,    0.044802370851755174,  0.044802370851755174,
             0.044802370851755174, -0.8586508742123365,   -0.508629699630796,     0.044802370851755174,
             0.044802370851755174, -0.8586508742123365,    0.044802370851755174, -0.508629699630796,
             -0.03381941603233842,  -0.9982828964265062,   -0.03381941603233842,  -0.03381941603233842,
             -0.37968289875261624,  -0.37968289875261624,  -0.753341017856078,    -0.37968289875261624,
             -0.4321472685365301,   -0.4321472685365301,   -0.7821684431180708,    0.12128480194602098,
             -0.4321472685365301,    0.12128480194602098,  -0.7821684431180708,   -0.4321472685365301,
             0.12128480194602098,  -0.4321472685365301,   -0.7821684431180708,   -0.4321472685365301,
             -0.508629699630796,     0.044802370851755174, -0.8586508742123365,    0.044802370851755174,
             0.044802370851755174, -0.508629699630796,    -0.8586508742123365,    0.044802370851755174,
             0.044802370851755174,  0.044802370851755174, -0.8586508742123365,   -0.508629699630796,
             -0.03381941603233842,  -0.03381941603233842,  -0.9982828964265062,   -0.03381941603233842,
             -0.37968289875261624,  -0.37968289875261624,  -0.37968289875261624,  -0.753341017856078,
             -0.4321472685365301,   -0.4321472685365301,    0.12128480194602098,  -0.7821684431180708,
             -0.4321472685365301,    0.12128480194602098,  -0.4321472685365301,   -0.7821684431180708,
             0.12128480194602098,  -0.4321472685365301,   -0.4321472685365301,   -0.7821684431180708,
             -0.508629699630796,     0.044802370851755174,  0.044802370851755174, -0.8586508742123365,
             0.044802370851755174, -0.508629699630796,     0.044802370851755174, -0.8586508742123365,
             0.044802370851755174,  0.044802370851755174, -0.508629699630796,    -0.8586508742123365,
             -0.03381941603233842,  -0.03381941603233842,  -0.03381941603233842,  -0.9982828964265062,
             -0.3239847771997537,   -0.6740059517812944,   -0.3239847771997537,    0.5794684678643381,
             -0.4004672082940195,   -0.7504883828755602,    0.15296486218853164,   0.5029860367700724,
             0.15296486218853164,  -0.7504883828755602,   -0.4004672082940195,    0.5029860367700724,
             0.08164729285680945,  -0.8828161875373585,    0.08164729285680945,   0.4553054119602712,
             -0.08164729285680945,  -0.4553054119602712,   -0.08164729285680945,   0.8828161875373585,
             -0.15296486218853164,  -0.5029860367700724,    0.4004672082940195,    0.7504883828755602,
             0.4004672082940195,   -0.5029860367700724,   -0.15296486218853164,   0.7504883828755602,
             0.3239847771997537,   -0.5794684678643381,    0.3239847771997537,    0.6740059517812944,
             -0.3239847771997537,   -0.3239847771997537,   -0.6740059517812944,    0.5794684678643381,
             -0.4004672082940195,    0.15296486218853164,  -0.7504883828755602,    0.5029860367700724,
             0.15296486218853164,  -0.4004672082940195,   -0.7504883828755602,    0.5029860367700724,
             0.08164729285680945,   0.08164729285680945,  -0.8828161875373585,    0.4553054119602712,
             -0.08164729285680945,  -0.08164729285680945,  -0.4553054119602712,    0.8828161875373585,
             -0.15296486218853164,   0.4004672082940195,   -0.5029860367700724,    0.7504883828755602,
             0.4004672082940195,   -0.15296486218853164,  -0.5029860367700724,    0.7504883828755602,
             0.3239847771997537,    0.3239847771997537,   -0.5794684678643381,    0.6740059517812944,
             -0.3239847771997537,   -0.6740059517812944,    0.5794684678643381,   -0.3239847771997537,
             -0.4004672082940195,   -0.7504883828755602,    0.5029860367700724,    0.15296486218853164,
             0.15296486218853164,  -0.7504883828755602,    0.5029860367700724,   -0.4004672082940195,
             0.08164729285680945,  -0.8828161875373585,    0.4553054119602712,    0.08164729285680945,
             -0.08164729285680945,  -0.4553054119602712,    0.8828161875373585,   -0.08164729285680945,
             -0.15296486218853164,  -0.5029860367700724,    0.7504883828755602,    0.4004672082940195,
             0.4004672082940195,   -0.5029860367700724,    0.7504883828755602,   -0.15296486218853164,
             0.3239847771997537,   -0.5794684678643381,    0.6740059517812944,    0.3239847771997537,
             -0.3239847771997537,   -0.3239847771997537,    0.5794684678643381,   -0.6740059517812944,
             -0.4004672082940195,    0.15296486218853164,   0.5029860367700724,   -0.7504883828755602,
             0.15296486218853164,  -0.4004672082940195,    0.5029860367700724,   -0.7504883828755602,
             0.08164729285680945,   0.08164729285680945,   0.4553054119602712,   -0.8828161875373585,
             -0.08164729285680945,  -0.08164729285680945,   0.8828161875373585,   -0.4553054119602712,
             -0.15296486218853164,   0.4004672082940195,    0.7504883828755602,   -0.5029860367700724,
             0.4004672082940195,   -0.15296486218853164,   0.7504883828755602,   -0.5029860367700724,
             0.3239847771997537,    0.3239847771997537,    0.6740059517812944,   -0.5794684678643381,
             -0.3239847771997537,    0.5794684678643381,   -0.6740059517812944,   -0.3239847771997537,
             -0.4004672082940195,    0.5029860367700724,   -0.7504883828755602,    0.15296486218853164,
             0.15296486218853164,   0.5029860367700724,   -0.7504883828755602,   -0.4004672082940195,
             0.08164729285680945,   0.4553054119602712,   -0.8828161875373585,    0.08164729285680945,
             -0.08164729285680945,   0.8828161875373585,   -0.4553054119602712,   -0.08164729285680945,
             -0.15296486218853164,   0.7504883828755602,   -0.5029860367700724,    0.4004672082940195,
             0.4004672082940195,    0.7504883828755602,   -0.5029860367700724,   -0.15296486218853164,
             0.3239847771997537,    0.6740059517812944,   -0.5794684678643381,    0.3239847771997537,
             -0.3239847771997537,    0.5794684678643381,   -0.3239847771997537,   -0.6740059517812944,
             -0.4004672082940195,    0.5029860367700724,    0.15296486218853164,  -0.7504883828755602,
             0.15296486218853164,   0.5029860367700724,   -0.4004672082940195,   -0.7504883828755602,
             0.08164729285680945,   0.4553054119602712,    0.08164729285680945,  -0.8828161875373585,
             -0.08164729285680945,   0.8828161875373585,   -0.08164729285680945,  -0.4553054119602712,
             -0.15296486218853164,   0.7504883828755602,    0.4004672082940195,   -0.5029860367700724,
             0.4004672082940195,    0.7504883828755602,   -0.15296486218853164,  -0.5029860367700724,
             0.3239847771997537,    0.6740059517812944,    0.3239847771997537,   -0.5794684678643381,
             0.5794684678643381,   -0.3239847771997537,   -0.6740059517812944,   -0.3239847771997537,
             0.5029860367700724,   -0.4004672082940195,   -0.7504883828755602,    0.15296486218853164,
             0.5029860367700724,    0.15296486218853164,  -0.7504883828755602,   -0.4004672082940195,
             0.4553054119602712,    0.08164729285680945,  -0.8828161875373585,    0.08164729285680945,
             0.8828161875373585,   -0.08164729285680945,  -0.4553054119602712,   -0.08164729285680945,
             0.7504883828755602,   -0.15296486218853164,  -0.5029860367700724,    0.4004672082940195,
             0.7504883828755602,    0.4004672082940195,   -0.5029860367700724,   -0.15296486218853164,
             0.6740059517812944,    0.3239847771997537,   -0.5794684678643381,    0.3239847771997537,
             0.5794684678643381,   -0.3239847771997537,   -0.3239847771997537,   -0.6740059517812944,
             0.5029860367700724,   -0.4004672082940195,    0.15296486218853164,  -0.7504883828755602,
             0.5029860367700724,    0.15296486218853164,  -0.4004672082940195,   -0.7504883828755602,
             0.4553054119602712,    0.08164729285680945,   0.08164729285680945,  -0.8828161875373585,
             0.8828161875373585,   -0.08164729285680945,  -0.08164729285680945,  -0.4553054119602712,
             0.7504883828755602,   -0.15296486218853164,   0.4004672082940195,   -0.5029860367700724,
             0.7504883828755602,    0.4004672082940195,   -0.15296486218853164,  -0.5029860367700724,
             0.6740059517812944,    0.3239847771997537,    0.3239847771997537,   -0.5794684678643381,
             0.03381941603233842,   0.03381941603233842,   0.03381941603233842,   0.9982828964265062,
             -0.044802370851755174, -0.044802370851755174,  0.508629699630796,     0.8586508742123365,
             -0.044802370851755174,  0.508629699630796,    -0.044802370851755174,  0.8586508742123365,
             -0.12128480194602098,   0.4321472685365301,    0.4321472685365301,    0.7821684431180708,
             0.508629699630796,    -0.044802370851755174, -0.044802370851755174,  0.8586508742123365,
             0.4321472685365301,   -0.12128480194602098,   0.4321472685365301,    0.7821684431180708,
             0.4321472685365301,    0.4321472685365301,   -0.12128480194602098,   0.7821684431180708,
             0.37968289875261624,   0.37968289875261624,   0.37968289875261624,   0.753341017856078,
             0.03381941603233842,   0.03381941603233842,   0.9982828964265062,    0.03381941603233842,
             -0.044802370851755174,  0.044802370851755174,  0.8586508742123365,    0.508629699630796,
             -0.044802370851755174,  0.508629699630796,     0.8586508742123365,   -0.044802370851755174,
             -0.12128480194602098,   0.4321472685365301,    0.7821684431180708,    0.4321472685365301,
             0.508629699630796,    -0.044802370851755174,  0.8586508742123365,   -0.044802370851755174,
             0.4321472685365301,   -0.12128480194602098,   0.7821684431180708,    0.4321472685365301,
             0.4321472685365301,    0.4321472685365301,    0.7821684431180708,   -0.12128480194602098,
             0.37968289875261624,   0.37968289875261624,   0.753341017856078,     0.37968289875261624,
             0.03381941603233842,   0.9982828964265062,    0.03381941603233842,   0.03381941603233842,
             -0.044802370851755174,  0.8586508742123365,   -0.044802370851755174,  0.508629699630796,
             -0.044802370851755174,  0.8586508742123365,    0.508629699630796,    -0.044802370851755174,
             -0.12128480194602098,   0.7821684431180708,    0.4321472685365301,    0.4321472685365301,
             0.508629699630796,     0.8586508742123365,   -0.044802370851755174, -0.044802370851755174,
             0.4321472685365301,    0.7821684431180708,   -0.12128480194602098,   0.4321472685365301,
             0.4321472685365301,    0.7821684431180708,    0.4321472685365301,   -0.12128480194602098,
             0.37968289875261624,   0.753341017856078,     0.37968289875261624,   0.37968289875261624,
             0.9982828964265062,    0.03381941603233842,   0.03381941603233842,   0.03381941603233842,
             0.8586508742123365,   -0.044802370851755174, -0.044802370851755174,  0.508629699630796,
             0.8586508742123365,   -0.044802370851755174,  0.508629699630796,    -0.044802370851755174,
             0.7821684431180708,   -0.12128480194602098,   0.4321472685365301,    0.4321472685365301,
             0.8586508742123365,    0.508629699630796,    -0.044802370851755174, -0.044802370851755174,
             0.7821684431180708,    0.4321472685365301,   -0.12128480194602098,   0.4321472685365301,
             0.7821684431180708,    0.4321472685365301,    0.4321472685365301,   -0.12128480194602098,
             0.753341017856078,     0.37968289875261624,   0.37968289875261624,   0.37968289875261624,
        ]
        for i in 0..<grad4.count {
            grad4[i] = Float(grad4[i] / Float(Self.NORMALIZER_4D))
        }
        var j = 0
        for i in 0..<GRADIENTS_4D.count {
            if j == grad4.count {
                j = 0
            }
            GRADIENTS_4D[i] = grad4[j]
            j += 1
        }
        return GRADIENTS_4D
    }
}

extension OpenSimplex2CPU: OpenSimplex2 {
    public func noise2(seed: Int32, coord: SIMD2<Double>, variant: OpenSimplex2Noise2Variant) -> Float {
        return switch variant {
        case .standard:
            noise2_Standard(seed: Int(seed), x: coord.x, y: coord.y)
        case .x:
            noise2_ImproveX(seed: Int(seed), x: coord.x, y: coord.y)
        }
    }

    public func noise3(seed: Int32, coord: SIMD3<Double>, variant: OpenSimplex2Noise3Variant) -> Float {
        return switch variant {
        case .xy:
            noise3_ImproveXY(seed: Int(seed), x: coord.x, y: coord.y, z: coord.z)
        case .xz:
            noise3_ImproveXZ(seed: Int(seed), x: coord.x, y: coord.y, z: coord.z)
        case .fallback:
            noise3_Fallback(seed: Int(seed), x: coord.x, y: coord.y, z: coord.z)
        }
    }

    public func noise4(seed: Int32, coord: SIMD4<Double>, variant: OpenSimplex2Noise4Variant) -> Float {
        return switch variant {
        case .xyz:
            noise4_ImproveXYZ(seed: Int(seed), x: coord.x, y: coord.y, z: coord.z, w: coord.w)
        case .xyz_xy:
            noise4_ImproveXYZ_ImproveXY(seed: Int(seed), x: coord.x, y: coord.y, z: coord.z, w: coord.w)
        case .xyz_xz:
            noise4_ImproveXYZ_ImproveXZ(seed: Int(seed), x: coord.x, y: coord.y, z: coord.z, w: coord.w)
        case .xy_zw:
            noise4_ImproveXY_ImproveZW(seed: Int(seed), x: coord.x, y: coord.y, z: coord.z, w: coord.w)
        case .fallback:
            noise4_Fallback(seed: Int(seed), x: coord.x, y: coord.y, z: coord.z, w: coord.w)
        }
    }

    public func noise2(seed: Int32, coords: [SIMD2<Double>], variant: OpenSimplex2Noise2Variant) -> [Float] {
        return coords.map { noise2(seed: seed, coord: $0, variant: variant) }
    }

    public func noise3(seed: Int32, coords: [SIMD3<Double>], variant: OpenSimplex2Noise3Variant) -> [Float] {
        return coords.map { noise3(seed: seed, coord: $0, variant: variant) }
    }

    public func noise4(seed: Int32, coords: [SIMD4<Double>], variant: OpenSimplex2Noise4Variant) -> [Float] {
        return coords.map { noise4(seed: seed, coord: $0, variant: variant) }
    }
}
