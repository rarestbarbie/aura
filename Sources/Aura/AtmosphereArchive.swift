import AuraDecoding
import Ion
import SystemIO
import SystemPackage

public struct AtmosphereArchive: Sendable, Equatable {
    public static let currentVersion: UInt32 = 1

    public var manifest: Manifest

    public var version: UInt32 {
        get { self.manifest.version }
        set { self.manifest.version = newValue }
    }

    public var planets: [PlanetEntry] {
        get { self.manifest.planets }
        set { self.manifest.planets = newValue }
    }

    public init(manifest: Manifest) {
        self.manifest = manifest
    }

    public init(
        version: UInt32 = AtmosphereArchive.currentVersion,
        planets: [PlanetEntry]
    ) {
        self.manifest = .init(version: version, planets: planets)
    }

    public subscript(name: String) -> PlanetEntry? {
        self.manifest[name]
    }
}

extension AtmosphereArchive {
    /// Serializes the archive as a Gzip-compressed binary Ion structure.
    public func serialize() throws -> [UInt8] {
        let ion: Ion = .encode(atomic: self.manifest)
        return TableCompression.deflate(Array(ion.bytes), level: 7)
    }

    /// Decompresses (if gzipped) and deserializes an AtmosphereArchive Ion structure.
    public static func deserialize(from archiveBytes: [UInt8]) throws -> AtmosphereArchive {
        let uncompressed: [UInt8]
        if archiveBytes.starts(with: [0x1f, 0x8b]) {
            uncompressed = try TableCompression.inflate(archiveBytes)
        } else {
            uncompressed = archiveBytes
        }

        let manifest: Manifest = try Ion(bytes: uncompressed[...]).decode(atomic: Manifest.self)
        guard manifest.version == Self.currentVersion else {
            throw Error.unsupportedVersion(manifest.version)
        }
        return .init(manifest: manifest)
    }

    /// Extracts and decodes a specific lookup table for a planet.
    public func extractTable(
        for planet: String,
        table tableName: String
    ) throws -> [SIMD4<Float>] {
        guard let planetEntry: PlanetEntry = self.manifest[planet] else {
            throw Error.planetNotFound(planet)
        }
        guard let descriptor: TableDescriptor = planetEntry.tables[tableName] else {
            throw Error.tableNotFound(tableName)
        }

        return AtmosphereTableDecoder.decode(
            shuffled: descriptor.data,
            width: descriptor.width,
            height: descriptor.height,
            depth: descriptor.depth ?? 1
        )
    }

    /// Bakes one or more atmospheric configurations into a unified archive.
    public static func bake(
        configs: [AtmosphereConfig],
        detail: Int = 3
    ) throws -> AtmosphereArchive {
        guard 1 ... 5 ~= detail else {
            throw AtmosphereError.invalidDetail(detail)
        }

        var planets: [PlanetEntry] = []

        for config: AtmosphereConfig in configs {
            let atmosphere: Atmosphere = .from(
                config: config,
                resolutions: (
                    transmittance: .init(32, 8)       &<< detail,
                    scattering: .init(4, 16, 4, 1) &<< detail,
                    irradiance: .init(8, 2)        &<< detail
                )
            )

            let (transmittance, mie, scattering, irradiance) = atmosphere.tables()

            // 1. Transmittance table
            let transmittanceWidth: Int = atmosphere.resolution.transmittance.x
            let transmittanceHeight: Int = atmosphere.resolution.transmittance.y
            let transmittanceBuffer: [SIMD4<Float>] = transmittance.buffer.map {
                .init(.init($0.x), .init($0.y), .init($0.z), 1.0)
            }
            let transmittanceShuffled: [UInt8] = TableCompression.filterAndShuffle(
                simd4: transmittanceBuffer,
                width: transmittanceWidth,
                height: transmittanceHeight,
                depth: 1
            )

            // 2. Scattering table (Mie merged into W)
            let scatteringWidth: Int = atmosphere.resolution.scattering.x
            let scatteringHeight: Int = atmosphere.resolution.scattering.y
            let scatteringDepth: Int = atmosphere.resolution.scattering.z
            let scatteringBuffer: [SIMD4<Float>] = zip(scattering.buffer, mie.buffer).map {
                .init(.init($0.x), .init($0.y), .init($0.z), .init($1.x))
            }
            let scatteringShuffled: [UInt8] = TableCompression.filterAndShuffle(
                simd4: scatteringBuffer,
                width: scatteringWidth,
                height: scatteringHeight,
                depth: scatteringDepth
            )

            // 3. Irradiance table
            let irradianceWidth: Int = atmosphere.resolution.irradiance.x
            let irradianceHeight: Int = atmosphere.resolution.irradiance.y
            let irradianceBuffer: [SIMD4<Float>] = irradiance.buffer.map {
                .init(.init($0.x), .init($0.y), .init($0.z), 1.0)
            }
            let irradianceShuffled: [UInt8] = TableCompression.filterAndShuffle(
                simd4: irradianceBuffer,
                width: irradianceWidth,
                height: irradianceHeight,
                depth: 1
            )

            // 4. Physical parameters & resolutions
            let serialized: [Float] = atmosphere.serialized.map(Float.init)
            let params: AtmosphereParameters = .init(
                radius_bottom: serialized[0],
                radius_top: serialized[1],
                radius_sun: serialized[2],
                mu_s_min: serialized[3],
                rayleigh_scattering: [serialized[4], serialized[5], serialized[6]],
                mie_scattering: [serialized[7], serialized[8], serialized[9]],
                mie_g: serialized[10],
                resolution_transmittance: [.init(serialized[11]), .init(serialized[12])],
                resolution_scattering4_R: .init(serialized[13]),
                resolution_scattering4_M: .init(serialized[14]),
                resolution_scattering4_MS: .init(serialized[15]),
                resolution_scattering4_N: .init(serialized[16]),
                resolution_irradiance: [.init(serialized[17]), .init(serialized[18])],
                irradiance: [serialized[19], serialized[20], serialized[21]]
            )

            let transmittanceDescriptor: TableDescriptor = .init(
                width: transmittanceWidth,
                height: transmittanceHeight,
                depth: nil,
                data: transmittanceShuffled
            )

            let scatteringDescriptor: TableDescriptor = .init(
                width: scatteringWidth,
                height: scatteringHeight,
                depth: scatteringDepth,
                data: scatteringShuffled
            )

            let irradianceDescriptor: TableDescriptor = .init(
                width: irradianceWidth,
                height: irradianceHeight,
                depth: nil,
                data: irradianceShuffled
            )

            let entry: PlanetEntry = .init(
                name: config.name,
                parameters: params,
                tables: .init(
                    transmittance: transmittanceDescriptor,
                    scattering: scatteringDescriptor,
                    irradiance: irradianceDescriptor
                )
            )
            planets.append(entry)
        }

        return .init(
            manifest: .init(version: Self.currentVersion, planets: planets)
        )
    }

    /// Serializes and writes the compressed archive to the specified file path.
    public func write(to path: FilePath) throws {
        let compressedBytes: [UInt8] = try self.serialize()
        _ = try path.open(
            .writeOnly,
            permissions: (.rw, .rw, .r),
            options: [.create, .truncate]
        ) { descriptor in
            try compressedBytes.withUnsafeBytes { raw in
                try descriptor.writeAll(raw)
            }
        }
    }
}
