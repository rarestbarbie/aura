struct _TableTransmittance<F>: Table.D2 where F: SwiftFloatingPoint {
    let atmosphere: Atmosphere<F>
    var buffer: [Vector3<F>]

    var size: Vector2<Int> {
        self.atmosphere.resolution.transmittance
    }

    // transmittance to top
    var top: Top {
        .init(table: self)
    }
    struct Top {
        let table: Table.Transmittance<F>

        subscript(r r: F, μ μ: F) -> Vector3<F> {
            self.table.atmosphere.assert(r: r, μ: μ)
            let t: Vector2<F> = self.table.atmosphere.transmittanceTextureCoordinate(r: r, μ: μ)
            return self.table[t]
        }
    }

    // transmittance to sun
    var sun: Sun {
        .init(table: self)
    }
    struct Sun {
        let table: Table.Transmittance<F>

        subscript(r r: F, μs μs: F) -> Vector3<F> {
            let α: F   = self.table.atmosphere.radius.sun
            let sin: F = self.table.atmosphere.radius.bottom / r,
            cos: F = -F.sqrt(max(0, 1 - sin * sin))
            return self.table.top[r: r, μ: μs] * Atmosphere<F>.smoothstep(
                -sin * α,
                sin * α,
                t: μs - cos
            )
        }
    }
}

// single scattering
extension Table.Transmittance {
    subscript(r r: F, μ μ: F, d d: F, intersectsGround intersectsGround: Bool) -> Vector3<F> {
        self.atmosphere.assert(r: r, μ: μ)
        Swift.assert(d >= 0)

        let q: F   = (d * d as F) + (2 * r * μ * d as F) + (r * r as F)
        let rd: F  = self.atmosphere.clamp(r: F.sqrt(q))
        let μd: F  = max(-1, min((r * μ + d) / rd, 1))
        if intersectsGround {
            let transmittance: Vector3<F> = self.top[r: rd, μ: -μd] / self.top[r: r, μ: -μ]
            return .min(transmittance, .init(repeating: 1))
        } else {
            let transmittance: Vector3<F> = self.top[r: r, μ: μ] / self.top[r: rd, μ: μd]
            return .min(transmittance, .init(repeating: 1))
        }
    }

    func singleScatteringIntegrand(r: F, μ: F, μs: F, ν: F, d: F, intersectsGround: Bool)
    -> (rayleigh: Vector3<F>, mie: Vector3<F>) {
        let q: F   = (d * d as F) + (2 * r * μ * d as F) + (r * r as F)
        let rd: F  = self.atmosphere.clamp(r: F.sqrt(q))
        let μsd: F = max(-1, min((r * μs + d * ν) / rd, 1))
        let transmittance: Vector3<F> =
        self[r: r, μ: μ, d: d, intersectsGround: intersectsGround] * self.sun[r: rd, μs: μsd]
        return (
            transmittance * self.atmosphere.rayleigh.density[
                altitude: rd - self.atmosphere.radius.bottom
            ],
            transmittance * self.atmosphere.mie.density     [
                altitude: rd - self.atmosphere.radius.bottom
            ]
        )
    }

    // integral
    func singleScattering(r: F, μ: F, μs: F, ν: F, intersectsGround: Bool, samples: Int = 50)
    -> (rayleigh: Vector3<F>, mie: Vector3<F>) {
        self.atmosphere.assert(r: r, μ: μ)
        Atmosphere.assert(μs: μs, ν: ν)
        let l: F  = self.atmosphere.distanceToBoundary(
            r: r,
            μ: μ,
            intersectsGround: intersectsGround
        ),
        Δx: F = l / .init(samples)
        // perform integral
        var sum: (rayleigh: Vector3<F>, mie: Vector3<F>) = (.zero, .zero)
        for i: Int in 0 ... samples /* inclusive range because trapezoidal rule*/ {
            let d: F = .init(i) * Δx
            let (Rs, Ms): (Vector3<F>, Vector3<F>) =
            self.singleScatteringIntegrand(
                r: r, μ: μ, μs: μs, ν: ν, d: d,
                intersectsGround: intersectsGround
            )
            // trapezoidal rule
            let w: F = i == 0 || i == samples ? 0.5 : 1
            sum.rayleigh += Rs * w
            sum.mie      += Ms * w
        }

        return (
            sum.rayleigh * Δx * self.atmosphere.irradiance * self.atmosphere.rayleigh.scattering,
            sum.mie      * Δx * self.atmosphere.irradiance * self.atmosphere.mie.scattering
        )
    }

    func singleScattering(texel: Vector3<F>) -> (rayleigh: Vector3<F>, mie: Vector3<F>) {
        let (r, μ, μs, ν, intersectsGround): (r: F, μ: F, μs: F, ν: F, intersectsGround: Bool) =
        self.atmosphere.scatteringTextureParameter(texel: texel)
        return self.singleScattering(
            r: r,
            μ: μ,
            μs: μs,
            ν: ν,
            intersectsGround: intersectsGround
        )
    }
}


extension Table.Transmittance: CustomStringConvertible {
    var description: String {
        """
        Transmittance table [\(self.size.x), \(self.size.y)]
        {
        \((0 ..< self.size.y).map {
                (y: Int) in
                return """
                    [\(y)]:
                \((0 ..< self.size.x).map {
                        (x: Int) in

                        let color: Vector3<F> = self.buffer[y * self.size.x + x]
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
        }
        """
    }
}
