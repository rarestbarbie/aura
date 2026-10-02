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
        configs: [AtmosphereConfig],
        detail: Int = 3,
        to file: FilePath
    ) throws {
        let archive: AtmosphereArchive = try .bake(configs: configs, detail: detail)
        try archive.write(to: file)
    }

    public static func bake(
        config: AtmosphereConfig,
        detail: Int = 3,
        to directory: FilePath
    ) throws {
        try FilePath.Directory(path: directory).create()
        let archive: AtmosphereArchive = try .bake(configs: [config], detail: detail)
        let filePath: FilePath = directory.appending("atmosphere.bin.gz")
        try archive.write(to: filePath)
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
