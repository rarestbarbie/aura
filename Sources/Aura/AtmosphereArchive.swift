import Foundation
import SystemIO
import SystemPackage

public struct AtmosphereArchive: Sendable {
    public static let magic: [UInt8] = [0x41, 0x55, 0x52, 0x41] // "AURA"
    public static let currentVersion: UInt32 = 1

    public var manifest: Manifest
    public var payload: [UInt8]

    public init(manifest: Manifest, payload: [UInt8]) {
        self.manifest = manifest
        self.payload = payload
    }
}

extension AtmosphereArchive {
    /// Serializes the archive container (header, manifest JSON, and data payload)
    /// and compresses the entire package with Gzip.
    public func serialize() throws -> [UInt8] {
        let encoder: JSONEncoder = .init()
        let manifestData: Data = try encoder.encode(self.manifest)
        let manifestBytes: [UInt8] = .init(manifestData)

        let headerSize: Int = 12
        var uncompressed: [UInt8] = []
        uncompressed.reserveCapacity(headerSize + manifestBytes.count + self.payload.count)

        // 1. Magic: "AURA"
        uncompressed.append(contentsOf: Self.magic)

        // 2. Format version: UInt32 LE
        var versionLE: UInt32 = self.manifest.version.littleEndian
        withUnsafeBytes(of: &versionLE) { uncompressed.append(contentsOf: $0) }

        // 3. Manifest byte length: UInt32 LE
        var manifestLenLE: UInt32 = UInt32(manifestBytes.count).littleEndian
        withUnsafeBytes(of: &manifestLenLE) { uncompressed.append(contentsOf: $0) }

        // 4. Manifest JSON bytes
        uncompressed.append(contentsOf: manifestBytes)

        // 5. Payload (filtered and shuffled table bytes)
        uncompressed.append(contentsOf: self.payload)

        // 6. Gzip compression
        return TableCompression.deflate(uncompressed, level: 7)
    }

    /// Decompresses a Gzip package and deserializes the container.
    public static func deserialize(from archiveBytes: [UInt8]) throws -> AtmosphereArchive {
        let uncompressed: [UInt8] = try TableCompression.inflate(archiveBytes)
        guard uncompressed.count >= 12 else {
            throw Error.corruptHeader
        }

        guard uncompressed.prefix(4) == Self.magic[...] else {
            throw Error.invalidMagic
        }

        let version: UInt32 = uncompressed[4 ..< 8].withUnsafeBytes {
            $0.load(as: UInt32.self).littleEndian
        }
        guard version == Self.currentVersion else {
            throw Error.unsupportedVersion(version)
        }

        let manifestLength: Int = Int(uncompressed[8 ..< 12].withUnsafeBytes {
            $0.load(as: UInt32.self).littleEndian
        })
        guard uncompressed.count >= 12 + manifestLength else {
            throw Error.corruptHeader
        }

        let manifestBytes: [UInt8] = .init(uncompressed[12 ..< 12 + manifestLength])
        let manifestData: Data = .init(manifestBytes)
        let manifest: Manifest
        do {
            manifest = try JSONDecoder().decode(Manifest.self, from: manifestData)
        } catch {
            throw Error.corruptManifest
        }

        let payload: [UInt8] = .init(uncompressed.suffix(from: 12 + manifestLength))
        return .init(manifest: manifest, payload: payload)
    }

    /// Extracts and decodes a specific lookup table for a planet.
    public func extractTable(for planet: String, table tableName: String) throws -> [SIMD4<Float>] {
        guard let planetEntry = self.manifest.planets[planet] else {
            throw Error.planetNotFound(planet)
        }
        guard let descriptor = planetEntry.tables[tableName] else {
            throw Error.tableNotFound(tableName)
        }
        guard self.payload.count >= descriptor.offset + descriptor.length else {
            throw Error.bufferOutOfBounds
        }

        let tableBytes: [UInt8] = .init(self.payload[descriptor.offset ..< descriptor.offset + descriptor.length])
        return TableCompression.unshuffleAndUnfilter(
            shuffled: tableBytes,
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

        var planets: [String: PlanetEntry] = [:]
        var payload: [UInt8] = []

        for config: AtmosphereConfig in configs {
            let atmosphere: Atmosphere<Double> = .from(
                config: config,
                resolutions: (
                    transmittance: .init(32, 8)       &<< detail,
                    scattering:    .init(4, 16, 4, 1) &<< detail,
                    irradiance:    .init(8, 2)        &<< detail
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

            var tables: [String: TableDescriptor] = [:]

            let transOffset: Int = payload.count
            payload.append(contentsOf: transShuffled)
            tables["transmittance"] = .init(
                width: transWidth,
                height: transHeight,
                depth: nil,
                offset: transOffset,
                length: transShuffled.count
            )

            let scatOffset: Int = payload.count
            payload.append(contentsOf: scatShuffled)
            tables["scattering"] = .init(
                width: scatWidth,
                height: scatHeight,
                depth: scatDepth,
                offset: scatOffset,
                length: scatShuffled.count
            )

            let irradOffset: Int = payload.count
            payload.append(contentsOf: irradShuffled)
            tables["irradiance"] = .init(
                width: irradWidth,
                height: irradHeight,
                depth: nil,
                offset: irradOffset,
                length: irradShuffled.count
            )

            planets[config.name] = .init(parameters: params, tables: tables)
        }

        return .init(
            manifest: .init(version: Self.currentVersion, planets: planets),
            payload: payload
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
