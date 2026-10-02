import SystemIO
import SystemPackage
import struct Foundation.Data
import class Foundation.JSONEncoder

public enum AtmosphereError: Error, Sendable {
    case invalidDetail(Int)
    case invalidConfigFile(String)
}

public enum AtmosphereBaker {
    public static func bake(
        config: AtmosphereConfig,
        detail: Int = 3,
        to directory: FilePath
    ) throws {
        guard 1 ... 5 ~= detail else {
            throw AtmosphereError.invalidDetail(detail)
        }

        let atmosphere: Atmosphere<Double> = .from(
            config: config,
            resolutions: (
                transmittance: .init(32, 8)       &<< detail,
                scattering:    .init(4, 16, 4, 1) &<< detail,
                irradiance:    .init(8, 2)        &<< detail
            )
        )

        let (transmittance, mie, scattering, irradiance) = atmosphere.tables()

        try FilePath.Directory(path: directory).create()

        // 1. transmittance.bin
        let transBuffer: [SIMD4<Float>] = transmittance.buffer.map {
            SIMD4<Float>(Float($0.x), Float($0.y), Float($0.z), 1.0)
        }
        let transPath: FilePath = directory.appending("transmittance.bin")
        _ = try transPath.open(
            .writeOnly,
            permissions: (.rw, .rw, .r),
            options: [.create, .truncate]
        ) { descriptor in
            try transBuffer.withUnsafeBytes { raw in
                try descriptor.writeAll(raw)
            }
        }

        // 2. scattering.bin
        let scatBuffer: [SIMD4<Float>] = zip(scattering.buffer, mie.buffer).map {
            SIMD4<Float>(Float($0.x), Float($0.y), Float($0.z), Float($1.x))
        }
        let scatPath: FilePath = directory.appending("scattering.bin")
        _ = try scatPath.open(
            .writeOnly,
            permissions: (.rw, .rw, .r),
            options: [.create, .truncate]
        ) { descriptor in
            try scatBuffer.withUnsafeBytes { raw in
                try descriptor.writeAll(raw)
            }
        }

        let compressedScat: [UInt8] = TableCompression.compress(
            simd4: scatBuffer,
            width: atmosphere.resolution.scattering.x,
            height: atmosphere.resolution.scattering.y,
            depth: atmosphere.resolution.scattering.z
        )
        let scatGzPath: FilePath = directory.appending("scattering.bin.gz")
        _ = try scatGzPath.open(
            .writeOnly,
            permissions: (.rw, .rw, .r),
            options: [.create, .truncate]
        ) { descriptor in
            try compressedScat.withUnsafeBytes { raw in
                try descriptor.writeAll(raw)
            }
        }

        // 3. irradiance.bin
        let irradBuffer: [SIMD4<Float>] = irradiance.buffer.map {
            SIMD4<Float>(Float($0.x), Float($0.y), Float($0.z), 1.0)
        }
        let irradPath: FilePath = directory.appending("irradiance.bin")
        _ = try irradPath.open(
            .writeOnly,
            permissions: (.rw, .rw, .r),
            options: [.create, .truncate]
        ) { descriptor in
            try irradBuffer.withUnsafeBytes { raw in
                try descriptor.writeAll(raw)
            }
        }

        // 4. parameters.json
        let p: [Float] = atmosphere.serialized.map(Float.init)
        let params: AtmosphereParameters = .init(
            radius_bottom: p[0],
            radius_top: p[1],
            radius_sun: p[2],
            mu_s_min: p[3],
            rayleigh_scattering: [p[4], p[5], p[6]],
            mie_scattering: [p[7], p[8], p[9]],
            mie_g: p[10],
            resolution_transmittance: [Int(p[11]), Int(p[12])],
            resolution_scattering4_R: Int(p[13]),
            resolution_scattering4_M: Int(p[14]),
            resolution_scattering4_MS: Int(p[15]),
            resolution_scattering4_N: Int(p[16]),
            resolution_irradiance: [Int(p[17]), Int(p[18])],
            irradiance: [p[19], p[20], p[21]]
        )

        let encoder: JSONEncoder = .init()
        encoder.outputFormatting = [.prettyPrinted]
        let jsonData: Data = try encoder.encode(params)
        let jsonPath: FilePath = directory.appending("parameters.json")
        _ = try jsonPath.open(
            .writeOnly,
            permissions: (.rw, .rw, .r),
            options: [.create, .truncate]
        ) { descriptor in
            try jsonData.withUnsafeBytes { raw in
                try descriptor.writeAll(raw)
            }
        }
    }

    public static func bakeEarth(
        detail: Int = 3,
        to directory: FilePath
    ) throws {
        try bake(config: .earth, detail: detail, to: directory)
    }
}

extension Atmosphere where F == Double {
    static func from(
        config: AtmosphereConfig,
        resolutions resolution: (
            transmittance: Vector2<Int>,
            scattering: Vector4<Int>,
            irradiance: Vector2<Int>
        )
    ) -> Atmosphere<Double> {
        Swift.assert(resolution.transmittance / 2 &* 2 == resolution.transmittance)
        Swift.assert(resolution.scattering    / 2 &* 2 == resolution.scattering)
        Swift.assert(resolution.irradiance    / 2 &* 2 == resolution.irradiance)

        let smax: Double = config.max_sun_zenith_angle / 180.0 * .pi

        let rayleighLayer: DensityProfile.Layer = .init(
            coefficients: (1, 0, 0),
            H: config.rayleigh_scale_height
        )
        let rayleighScattering: Vector3<Double> = .init(
            config.rayleigh_scattering[0],
            config.rayleigh_scattering[1],
            config.rayleigh_scattering[2]
        )

        let mieLayer: DensityProfile.Layer = .init(
            coefficients: (1, 0, 0),
            H: config.mie_scale_height
        )
        let mieScattering: Vector3<Double> = .init(
            config.mie_scattering[0],
            config.mie_scattering[1],
            config.mie_scattering[2]
        )
        let mieExtinction: Vector3<Double>
        if let extinction = config.mie_extinction, extinction.count == 3 {
            mieExtinction = .init(extinction[0], extinction[1], extinction[2])
        } else {
            let albedo: Double = config.mie_albedo ?? 0.9
            mieExtinction = mieScattering / albedo
        }

        let ozoneProfile: DensityProfile
        let ozoneExtinction: Vector3<Double>
        if let ozone = config.ozone_extinction, ozone.count == 3 {
            let alt: Double = config.ozone_altitude ?? 25000.0
            let thick: Double = config.ozone_thickness ?? 15000.0
            let ozoneLayer0: DensityProfile.Layer = .init(
                thickness: alt,
                coefficients: (0, 1.0 / thick, -(alt - thick) / thick),
                H: .infinity
            )
            let ozoneLayer1: DensityProfile.Layer = .init(
                coefficients: (0, -1.0 / thick, (alt + thick) / thick),
                H: .infinity
            )
            ozoneProfile = .init(ozoneLayer0, ozoneLayer1)
            ozoneExtinction = .init(ozone[0], ozone[1], ozone[2])
        } else {
            let zeroLayer: DensityProfile.Layer = .init(
                coefficients: (0, 0, 0),
                H: 1
            )
            ozoneProfile = .init(zeroLayer)
            ozoneExtinction = .zero
        }

        let solarIrradiance: Vector3<Double> = .init(
            config.solar_irradiance[0],
            config.solar_irradiance[1],
            config.solar_irradiance[2]
        )

        let groundAlbedo: Vector3<Double> = .init(
            config.ground_albedo[0],
            config.ground_albedo[1],
            config.ground_albedo[2]
        )

        return .init(
            radius: (bottom: config.radius_bottom, top: config.radius_top, sun: config.sun_angular_radius),
            rayleigh: (.init(rayleighLayer), scattering: rayleighScattering),
            mie: (.init(mieLayer), scattering: mieScattering, extinction: mieExtinction, g: config.mie_g),
            absorption: (ozoneProfile, extinction: ozoneExtinction),
            irradiance: solarIrradiance,
            ground: groundAlbedo,
            μsmin: .cos(smax),
            resolution: (
                resolution.transmittance,
                .init(
                    resolution.scattering.w * resolution.scattering.z,
                    resolution.scattering.y,
                    resolution.scattering.x
                ),
                (
                    R:  resolution.scattering.x,
                    M:  resolution.scattering.y,
                    MS: resolution.scattering.z,
                    N:  resolution.scattering.w
                ),
                resolution.irradiance
            )
        )
    }
}
