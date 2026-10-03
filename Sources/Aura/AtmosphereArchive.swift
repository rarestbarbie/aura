import AuraDecoding
public import Ion
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

extension AtmosphereArchive: IonEncodable {
    public typealias NullGroup = Manifest.NullGroup

    public func encode(to ion: inout Ion.NodeEncoder) {
        self.manifest.encode(to: &ion)
    }
}

extension AtmosphereArchive: IonDecodable {
    public init(ion: borrowing Ion.NodeDecoder) throws {
        self.init(manifest: try .init(ion: ion))
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
            let transWidth: Int = atmosphere.resolution.transmittance.x
            let transHeight: Int = atmosphere.resolution.transmittance.y
            let transBuffer: [SIMD4<Float>] = transmittance.buffer.map {
                SIMD4<Float>(Float($0.x), Float($0.y), Float($0.z), 1.0)
            }
            let transShuffled: [UInt8] = TableCompression.filterAndShuffle(
                simd4: transBuffer,
                width: transWidth,
                height: transHeight,
                depth: 1
            )

            // 2. Scattering table (Mie merged into W)
            let scatWidth: Int = atmosphere.resolution.scattering.x
            let scatHeight: Int = atmosphere.resolution.scattering.y
            let scatDepth: Int = atmosphere.resolution.scattering.z
            let scatBuffer: [SIMD4<Float>] = zip(scattering.buffer, mie.buffer).map {
                SIMD4<Float>(Float($0.x), Float($0.y), Float($0.z), Float($1.x))
            }
            let scatShuffled: [UInt8] = TableCompression.filterAndShuffle(
                simd4: scatBuffer,
                width: scatWidth,
                height: scatHeight,
                depth: scatDepth
            )

            // 3. Irradiance table
            let irradWidth: Int = atmosphere.resolution.irradiance.x
            let irradHeight: Int = atmosphere.resolution.irradiance.y
            let irradBuffer: [SIMD4<Float>] = irradiance.buffer.map {
                SIMD4<Float>(Float($0.x), Float($0.y), Float($0.z), 1.0)
            }
            let irradShuffled: [UInt8] = TableCompression.filterAndShuffle(
                simd4: irradBuffer,
                width: irradWidth,
                height: irradHeight,
                depth: 1
            )

            // 4. Physical parameters & resolutions
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

            let transDesc: TableDescriptor = .init(
                width: transWidth,
                height: transHeight,
                depth: nil,
                data: transShuffled
            )

            let scatDesc: TableDescriptor = .init(
                width: scatWidth,
                height: scatHeight,
                depth: scatDepth,
                data: scatShuffled
            )

            let irradDesc: TableDescriptor = .init(
                width: irradWidth,
                height: irradHeight,
                depth: nil,
                data: irradShuffled
            )

            let entry: PlanetEntry = .init(
                name: config.name,
                parameters: params,
                tables: .init(
                    transmittance: transDesc,
                    scattering: scatDesc,
                    irradiance: irradDesc
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
