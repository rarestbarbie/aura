struct _TableScattering<F>: Table.D3 where F: SwiftFloatingPoint {
    let atmosphere: Atmosphere<F>
    var buffer: [Vector3<F>]

    var size: Vector3<Int> {
        self.atmosphere.resolution.scattering
    }
}

extension Table.Scattering {
    subscript(
        r r: F,
        μ μ: F,
        μs μs: F,
        ν ν: F,
        intersectsGround intersectsGround: Bool
    ) -> Vector3<F> {
        let t: Vector4<F> = self.atmosphere.scatteringTextureCoordinate(
            r: r, μ: μ, μs: μs, ν: ν,
            intersectsGround: intersectsGround
        )
        let x: F = t.x * .init(self.atmosphere.resolution.scattering4.N - 1)
        let i: F = x.rounded(.down)
        let t3: (Vector3<F>, Vector3<F>) = (
            .init((i     + t.y) / .init(self.atmosphere.resolution.scattering4.N), t.z, t.w),
            .init((i + 1 + t.y) / .init(self.atmosphere.resolution.scattering4.N), t.z, t.w)
        )
        let u: F = x - i
        return self[t3.0] * (1 - u) + self[t3.1] * u
    }

    // called on multiple scattering texture
    // TODO: may not be the best place to define convenience function
    subscript(
        r r: F, μ μ: F, μs μs: F, ν ν: F, intersectsGround intersectsGround: Bool,
        n n: Int, rayleigh rayleigh: Self, mie mie: Self
    ) -> Vector3<F> {
        if n == 1 {
            let rayleigh: Vector3<F> =
            rayleigh[r: r, μ: μ, μs: μs, ν: ν, intersectsGround: intersectsGround]
            let mie: Vector3<F> =
            mie     [r: r, μ: μ, μs: μs, ν: ν, intersectsGround: intersectsGround]
            return rayleigh * Atmosphere<F>.Rφ(ν) + mie * Atmosphere<F>.Mφ(
                ν,
                g: self.atmosphere.mie.g
            )
        } else {
            return self[r: r, μ: μ, μs: μs, ν: ν, intersectsGround: intersectsGround]
        }
    }

    func density(
        r: F, μ: F, μs: F, ν: F, n: Int, samples: Int = 16,
        transmittance: Table.Transmittance<
            F
        >, rayleigh: Self, mie: Self, irradiance: Table.Irradiance<
            F
        >
    )
    -> Vector3<F> {
        self.atmosphere.assert(r: r, μ: μ)
        Atmosphere.assert(μs: μs, ν: ν)
        Swift.assert(n > 1)

        let zenith: Vector3<F> = .init(0, 0, 1)
        // view direction
        let ω: Vector3<F>    = .init(F.sqrt(1 - μ * μ), 0, μ)
        let sun: (x: F, y: F)
        sun.x               = ω.x == 0 ? 0 : (ν - μ * μs) / ω.x
        sun.y               = F.sqrt(max(0, 1 - sun.x * sun.x - μs * μs))
        let ωs: Vector3<F>   = .init(sun.x, sun.y, μs)

        let Δφ: F = .pi / .init(samples),
        Δθ: F = .pi / .init(samples)

        var combined: Vector3<F> = .zero
        for l: Int in 0 ..< samples {
            let θ: F = (.init(l) + 0.5) * Δθ
            var cos: (θ: F, φ: F),
            sin: (θ: F, φ: F)

            // only theta-dependent
            cos.θ   = F.cos(θ)
            sin.θ   = F.sin(θ)
            let intersectsGround: Bool   = self.atmosphere.intersectsGround(r: r, μ: cos.θ)
            var ground: (
                distance: F,
                albedo: Vector3<F>,
                transmittance: Vector3<F>,
                irradiance: Vector3<F>
            )
            if intersectsGround {
                ground.distance         = self.atmosphere.distanceToBottom(r: r, μ: cos.θ)
                ground.albedo           = self.atmosphere.ground
                ground.transmittance    = transmittance[
                    r: r,
                    μ: cos.θ,
                    d: ground.distance,
                    intersectsGround: true
                ]
            } else {
                ground.distance         = 0
                ground.albedo           = .zero
                ground.transmittance    = .zero
            }

            for m: Int in 0 ..< samples * 2 {
                let φ: F             = (.init(m) + 0.5) * Δφ

                cos.φ               = F.cos(φ)
                sin.φ               = F.sin(φ)
                let ωi: Vector3<F>   = .init(cos.φ * sin.θ, sin.φ * sin.θ, cos.θ)
                let Δωi: F           = Δθ * Δφ * sin.θ

                let νs: F            = ωs <> ωi
                let scattering: Vector3<F> =
                self[
                    r: r, μ: ωi.z, μs: μs, ν: νs, intersectsGround: intersectsGround,
                    n: n - 1, rayleigh: rayleigh, mie: mie
                ]

                // ground normal
                let g: Vector3<F>    = (zenith * r + ωi * ground.distance).normalized()
                ground.irradiance   = irradiance[r: atmosphere.radius.bottom, μs: g <> ωs]

                // incident radiance
                let incident: Vector3<F> =
                scattering + ground.albedo * ground.transmittance * ground.irradiance / .pi

                let νω: F            = ω <> ωi
                let density: (rayleigh: F, mie: F) = (
                    self.atmosphere.rayleigh.density[
                        altitude: r - self.atmosphere.radius.bottom
                    ],
                    self.atmosphere.mie.density     [
                        altitude: r - self.atmosphere.radius.bottom
                    ]
                )
                let anisotropic: (rayleigh: Vector3<F>, mie: Vector3<F>) = (
                    density.rayleigh * Atmosphere<F>.Rφ(
                        νω
                    )                           * self.atmosphere.rayleigh.scattering,
                    density.mie      * Atmosphere<F>.Mφ(
                        νω,
                        g: self.atmosphere.mie.g
                    ) * self.atmosphere.mie.scattering
                )

                combined += Δωi * incident * (anisotropic.rayleigh + anisotropic.mie)
            }
        }
        return combined
    }

    // integral, only call on a scattering density table
    func multipleScattering(
        r: F, μ: F, μs: F, ν: F, intersectsGround: Bool, samples: Int = 50,
        transmittance: Table.Transmittance<F>
    )
    -> Vector3<F> {
        self.atmosphere.assert(r: r, μ: μ)
        Atmosphere.assert(μs: μs, ν: ν)

        let l: F  = self.atmosphere.distanceToBoundary(
            r: r,
            μ: μ,
            intersectsGround: intersectsGround
        ),
        Δx: F = l / .init(samples)
        // perform integral
        var sum: Vector3<F> = .zero
        for i: Int in 0 ... samples /* inclusive range because trapezoidal rule*/ {
            let d: F     = .init(i) * Δx

            let q: F     = (d * d as F) + (2 * r * μ * d as F) + (r * r as F)
            let rd: F    = self.atmosphere.clamp(r: F.sqrt(q))
            let μd: F    = max(-1, min((r * μ  + d)     / rd, 1))
            let μsd: F   = max(-1, min((r * μs + d * ν) / rd, 1))

            let Ss: Vector3<
                F
            > = Δx * self[r: rd, μ: μd, μs: μsd, ν: ν, intersectsGround: intersectsGround] *
            transmittance[r: r,  μ: μ, d: d,           intersectsGround: intersectsGround]
            // trapezoidal rule
            let w: F = i == 0 || i == samples ? 0.5 : 1
            sum += Ss * w
        }

        return sum
    }


    func density(
        texel: Vector3<F>, n: Int,
        transmittance: Table.Transmittance<
            F
        >, rayleigh: Self, mie: Self, irradiance: Table.Irradiance<
            F
        >
    )
    -> Vector3<F> {
        let (r, μ, μs, ν, _): (r: F, μ: F, μs: F, ν: F, intersectsGround: Bool) =
        self.atmosphere.scatteringTextureParameter(texel: texel)
        return self.density(
            r: r, μ: μ, μs: μs, ν: ν, n: n,
            transmittance: transmittance, rayleigh: rayleigh, mie: mie, irradiance: irradiance
        )
    }

    func multipleScattering(texel: Vector3<F>, transmittance: Table.Transmittance<F>)
    -> (radiance: Vector3<F>, ν: F) {
        let (r, μ, μs, ν, intersectsGround): (r: F, μ: F, μs: F, ν: F, intersectsGround: Bool) =
        self.atmosphere.scatteringTextureParameter(texel: texel)
        let radiance: Vector3<F> = self.multipleScattering(
            r: r, μ: μ, μs: μs, ν: ν,
            intersectsGround: intersectsGround, transmittance: transmittance
        )
        return (radiance, ν)
    }
}

extension Table.Transmittance {
    func directIrradiance(r: F, μs: F) -> Vector3<F> {
        self.atmosphere.assert(r: r, μ: μs)

        let αs: F = self.atmosphere.radius.sun
        let average: F
        if      μs <= -αs {
            average = 0
        } else if μs <   αs {
            let β: F = μs + αs
            average = β * β / (4 * αs)
        } else {
            average = μs
        }

        return average * self.atmosphere.irradiance * self.top[r: r, μ: μs]
    }

    func directIrradiance(texel: Vector2<F>) -> Vector3<F> {
        let size: Vector2<F>     = .cast(self.atmosphere.resolution.irradiance)
        let (r, μs): (r: F, μs: F) = self.atmosphere.irradianceTextureParameter(texel / size)
        return self.directIrradiance(r: r, μs: μs)
    }
}
extension Table.Scattering /* multiple scattering table*/ {
    func indirectIrradiance(
        r: F,
        μs: F,
        n: Int,
        samples: Int = 32,
        rayleigh: Self,
        mie: Self
    ) -> Vector3<F> {
        self.atmosphere.assert(r: r, μ: μs)
        Swift.assert(n >= 1)

        let Δφ: F = .pi / .init(samples),
        Δθ: F = .pi / .init(samples)
        let ωs: Vector3<F>   = .init(F.sqrt(1 - μs * μs), 0, μs)
        var sum: Vector3<F>  = .zero
        for l: Int in 0 ..< samples / 2 {
            let θ: F = (.init(l) + 0.5) * Δθ

            var cos: (θ: F, φ: F),
            sin: (θ: F, φ: F)

            // only theta-dependent
            cos.θ   = F.cos(θ)
            sin.θ   = F.sin(θ)
            for m: Int in 0 ..< samples * 2 {
                let φ: F = (.init(m) + 0.5) * Δφ
                cos.φ   = F.cos(φ)
                sin.φ   = F.sin(φ)

                let ω: Vector3<F> = .init(cos.φ * sin.θ, sin.φ * sin.θ, cos.θ)
                let Δω: F         = Δθ * Δφ * sin.θ

                let ν: F = ω <> ωs
                sum    += Δω * ω.z * self[
                    r: r, μ: ω.z, μs: μs, ν: ν, intersectsGround: false,
                    n: n, rayleigh: rayleigh, mie: mie
                ]
            }
        }

        return sum
    }

    func indirectIrradiance(
        texel: Vector2<F>,
        n: Int,
        rayleigh: Self,
        mie: Self
    ) -> Vector3<F> {
        let size: Vector2<F>     = .cast(self.atmosphere.resolution.irradiance)
        let (r, μs): (r: F, μs: F) = self.atmosphere.irradianceTextureParameter(texel / size)
        return self.indirectIrradiance(r: r, μs: μs, n: n, rayleigh: rayleigh, mie: mie)
    }
}


extension Table.Scattering: CustomStringConvertible {
    var description: String {
        """
        Scattering table [\(self.size.x), \(self.size.y), \(self.size.z)]
        {
        \((0 ..< self.size.z).map {
                (z: Int) in
                return """
                \((0 ..< self.size.y).map {
                        (y: Int) in
                        return """
                            [\(z), \(y)]:
                        \((0 ..< self.size.x).map {
                                (x: Int) in
                                let color: Vector3<F> = self.buffer[
                                    (
                                        z * self.size.y + y
                                    ) * self.size.x + x
                                ]
                                return """
                                        [\(Highlight.pad("\(x)", left: 3))]: \(
                                    Highlight.swatch(color)
                                ) \(
                                    color
                                )
                                """
                            }.joined(separator: "\n"))
                        """
                    }.joined(separator: "\n"))
                """
            }.joined(separator: "\n"))
        """
    }
}
