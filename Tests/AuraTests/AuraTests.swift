@testable import Aura
import AuraDecoding
import Ion
import Testing

@Suite struct AuraTests {
    @Test static func EarthParametersMatch() throws {
        let resolutions: (
            transmittance: Vector2<Int>,
            scattering: Vector4<Int>,
            irradiance: Vector2<Int>
        ) = (
            transmittance: Vector2<Int>.init(32, 8)       &<< 1,
            scattering: Vector4<Int>.init(4, 16, 4, 1) &<< 1,
            irradiance: Vector2<Int>.init(8, 2)        &<< 1
        )
        let ref: Atmosphere = .earth(resolutions: resolutions)
        let config: AtmosphereConfig = try .parse(ion: earthIon)
        let parameterized: Atmosphere = .from(config: config, resolutions: resolutions)

        #expect(ref.serialized == parameterized.serialized)
        #expect(ref.ground == parameterized.ground)
        #expect(ref.absorption.extinction == parameterized.absorption.extinction)
    }

    @Test static func IonBinaryRoundtrip() throws {
        let config: AtmosphereConfig = try .parse(ion: earthIon)
        let ion: Ion = .encode(atomic: config)
        let decoded: AtmosphereConfig = try ion.decode(atomic: AtmosphereConfig.self)

        #expect(decoded.name == "Earth")
        #expect(decoded.radius_bottom == config.radius_bottom)
        #expect(decoded.radius_top == config.radius_top)
        #expect(decoded.rayleigh_scattering == config.rayleigh_scattering)
        #expect(decoded.mie_scattering == config.mie_scattering)
    }

    @Test static func IonTextParsing() throws {
        let config: AtmosphereConfig = try .parse(ion: earthIon)
        #expect(config.name == "Earth")
        #expect(config.radius_bottom == 6360000.0)
        #expect(config.mie_g == 0.8)
    }

    @Test static func TableCompressionRoundtrip() throws {
        // Create synthetic 3D volume with smooth gradients (like scattering table)
        let width: Int = 32
        let height: Int = 16
        let depth: Int = 4
        var data: [SIMD4<Float>] = []
        data.reserveCapacity(width * height * depth)

        for z: Int in 0 ..< depth {
            for y: Int in 0 ..< height {
                for x: Int in 0 ..< width {
                    let fx: Float = Float(x) / Float(width)
                    let fy: Float = Float(y) / Float(height)
                    let fz: Float = Float(z) / Float(depth)
                    data.append(.init(fx * 1.5, fy * 2.0, fz * 0.8, (fx + fy) * 0.2))
                }
            }
        }

        let compressed: [UInt8] = TableCompression.compress(
            simd4: data,
            width: width,
            height: height,
            depth: depth
        )

        #expect(compressed.count < data.count * MemoryLayout<SIMD4<Float>>.size)

        let decompressed: [SIMD4<Float>] = try TableCompression.decompress(
            archive: compressed,
            width: width,
            height: height,
            depth: depth
        )

        #expect(decompressed.count == data.count)
        #expect(decompressed == data)
    }

    @Test static func TableCompression2DRoundtrip() throws {
        // Test 2D table (e.g. transmittance / irradiance)
        let width: Int = 64
        let height: Int = 16
        var data: [SIMD4<Float>] = []
        data.reserveCapacity(width * height)

        for y: Int in 0 ..< height {
            for x: Int in 0 ..< width {
                let fx: Float = Float(x) / Float(width)
                let fy: Float = Float(y) / Float(height)
                data.append(.init(fx * 1.5, fy * 2.0, (fx + fy) * 0.5, 1.0))
            }
        }

        let compressed: [UInt8] = TableCompression.compress(
            simd4: data,
            width: width,
            height: height,
            depth: 1
        )

        let decompressed: [SIMD4<Float>] = try TableCompression.decompress(
            archive: compressed,
            width: width,
            height: height,
            depth: 1
        )

        #expect(decompressed.count == data.count)
        #expect(decompressed == data)
    }

    @Test static func AtmosphereTableDecoderDirect() throws {
        let width: Int = 16
        let height: Int = 8
        let depth: Int = 2
        var data: [SIMD4<Float>] = []
        data.reserveCapacity(width * height * depth)
        for z: Int in 0 ..< depth {
            for y: Int in 0 ..< height {
                for x: Int in 0 ..< width {
                    data.append(.init(Float(x), Float(y), Float(z), Float(x + y + z)))
                }
            }
        }

        let shuffled: [UInt8] = TableCompression.filterAndShuffle(
            simd4: data,
            width: width,
            height: height,
            depth: depth
        )

        let decoded: [SIMD4<Float>] = AtmosphereTableDecoder.decode(
            shuffled: shuffled,
            width: width,
            height: height,
            depth: depth
        )

        #expect(decoded == data)
    }

    @Test static func AtmosphereArchiveSinglePlanetRoundtrip() throws {
        let earthConfig: AtmosphereConfig = try .parse(ion: earthIon)
        let archive: AtmosphereArchive = try .bake(configs: [earthConfig], detail: 1)
        #expect(archive.manifest.planets["Earth"] != nil)
        #expect(archive.manifest.planets["earth"] == nil) // Distinct casing!

        let earthEntryBefore: AtmosphereArchive.PlanetEntry = try #require(
            archive.manifest.planets["Earth"]
        )
        let tables: [AtmosphereArchive.TableDescriptor] = [
            earthEntryBefore.tables.transmittance,
            earthEntryBefore.tables.scattering,
            earthEntryBefore.tables.irradiance,
        ]
        var totalRawBytes: Int = 0
        for desc: AtmosphereArchive.TableDescriptor in tables {
            let texels: Int = desc.width * desc.height * (desc.depth ?? 1)
            totalRawBytes += texels * MemoryLayout<SIMD4<Float>>.stride
        }

        let compressedBytes: [UInt8] = try archive.serialize()
        #expect(compressedBytes.count > 0)
        #expect(compressedBytes.count < totalRawBytes)

        let deserialized: AtmosphereArchive = try .deserialize(from: compressedBytes)
        #expect(deserialized.manifest.version == AtmosphereArchive.currentVersion)
        #expect(deserialized.manifest.planets.count == 1)

        let earthEntry: AtmosphereArchive.PlanetEntry = try #require(
            deserialized.manifest.planets["Earth"]
        )

        #expect(earthEntry.parameters.radius_bottom == 6360000.0)
        #expect(earthEntry.tables["transmittance"] != nil)
        #expect(earthEntry.tables["scattering"] != nil)
        #expect(earthEntry.tables["irradiance"] != nil)

        let trans: [SIMD4<Float>] = try deserialized.extractTable(
            for: "Earth",
            table: "transmittance"
        )
        let transDesc: AtmosphereArchive.TableDescriptor = try #require(
            earthEntry.tables["transmittance"]
        )
        #expect(trans.count == transDesc.width * transDesc.height)

        let scat: [SIMD4<Float>] = try deserialized.extractTable(
            for: "Earth",
            table: "scattering"
        )
        let scatDesc: AtmosphereArchive.TableDescriptor = try #require(
            earthEntry.tables["scattering"]
        )
        #expect(scat.count == scatDesc.width * scatDesc.height * (scatDesc.depth ?? 1))

        let irrad: [SIMD4<Float>] = try deserialized.extractTable(
            for: "Earth",
            table: "irradiance"
        )
        let irradDesc: AtmosphereArchive.TableDescriptor = try #require(
            earthEntry.tables["irradiance"]
        )
        #expect(irrad.count == irradDesc.width * irradDesc.height)
    }

    @Test static func AtmosphereArchiveMultiPlanetRoundtrip() throws {
        let earthConfig: AtmosphereConfig = try .parse(ion: earthIon)
        let marsConfig: AtmosphereConfig = try .parse(ion: marsIon)
        let archive: AtmosphereArchive = try .bake(
            configs: [earthConfig, marsConfig],
            detail: 1
        )
        #expect(archive.manifest.planets.count == 2)
        #expect(archive.manifest.planets["Earth"] != nil)
        #expect(archive.manifest.planets["Mars"] != nil)

        let compressed: [UInt8] = try archive.serialize()
        let deserialized: AtmosphereArchive = try .deserialize(from: compressed)

        #expect(deserialized.manifest.planets["Earth"] != nil)
        #expect(deserialized.manifest.planets["Mars"] != nil)
        #expect(deserialized.manifest.planets["Earth"]?.parameters.radius_bottom == 6360000.0)
        #expect(deserialized.manifest.planets["Mars"]?.parameters.radius_bottom == 3389500.0)

        let earthTrans: [SIMD4<Float>] = try deserialized.extractTable(
            for: "Earth",
            table: "transmittance"
        )
        let marsTrans: [SIMD4<Float>] = try deserialized.extractTable(
            for: "Mars",
            table: "transmittance"
        )
        #expect(earthTrans.count > 0)
        #expect(marsTrans.count > 0)
    }
}

extension AuraTests {
    static let earthIon: String = """
    {
        name: "Earth",
        radius_bottom: 6360000.0,
        radius_top: 6420000.0,
        sun_angular_radius: 0.004675,
        max_sun_zenith_angle: 102.0,
        rayleigh_scale_height: 8000.0,
        rayleigh_scattering: [5.8023393817123834e-06, 1.3557762447920223e-05, 3.3100005976367735e-05],
        mie_scale_height: 1200.0,
        mie_scattering: [3.996e-06, 3.996e-06, 3.996e-06],
        mie_extinction: [4.44e-06, 4.44e-06, 4.44e-06],
        mie_albedo: 0.9,
        mie_g: 0.8,
        ozone_extinction: [7.206534e-07, 1.7710017e-06, 6.5216177e-08],
        ozone_altitude: 25000.0,
        ozone_thickness: 15000.0,
        solar_irradiance: [1.49265, 1.850945, 1.7622550000000001],
        ground_albedo: [0.1, 0.1, 0.1]
    }
    """

    static let marsIon: String = """
    {
        name: "Mars",
        radius_bottom: 3389500.0,
        radius_top: 3450000.0,
        sun_angular_radius: 0.003067,
        max_sun_zenith_angle: 100.0,
        rayleigh_scale_height: 11100.0,
        rayleigh_scattering: [1.9e-07, 4.5e-07, 1.1e-06],
        mie_scale_height: 2000.0,
        mie_scattering: [4.0e-06, 3.2e-06, 2.0e-06],
        mie_extinction: [4.5e-06, 3.8e-06, 2.8e-06],
        mie_albedo: 0.85,
        mie_g: 0.7,
        solar_irradiance: [0.642, 0.796, 0.758],
        ground_albedo: [0.25, 0.15, 0.1]
    }
    """
}
