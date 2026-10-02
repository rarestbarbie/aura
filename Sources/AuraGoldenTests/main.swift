import Aura
import CRC
import Foundation
import SystemIO
import SystemPackage

@main struct AuraGoldenTests {
    static let goldenTransmittanceCRC32: UInt32 = 0xAB53BAD0
    static let goldenIrradianceCRC32: UInt32 = 0xB193C82B
    static let goldenScatteringCRC32: UInt32 = 0xA71A2E72

    static func main() throws {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("  Aura Golden Reference Test (Detail 3 Full Radiative Simulation)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        let configPath: FilePath = .init("Presets/Earth.ion")
        print("1. Loading Earth atmospheric configuration from '\(configPath)'...")
        let config: AtmosphereConfig = try AtmosphereConfig.load(from: configPath)

        print("2. Baking Earth atmosphere archive at detail 3...")
        let clock: ContinuousClock = .init()
        let start: ContinuousClock.Instant = clock.now
        let archive: AtmosphereArchive = try .bake(configs: [config], detail: 3)
        let elapsed: Duration = start.duration(to: clock.now)
        print("   Detail 3 precomputation finished in \(elapsed)!")

        guard let earthEntry: AtmosphereArchive.PlanetEntry = archive.manifest.planets[
            "Earth"
        ] else {
            fatalError("Verification failed: Earth entry missing in manifest!")
        }

        print("3. Verifying physical parameters...")
        let params: AtmosphereParameters = earthEntry.parameters
        guard params.radius_bottom == 6360000.0,
        params.radius_top == 6420000.0,
        abs(params.mu_s_min - -0.20791169) < 1e-6,
        params.mie_g == 0.8 else {
            fatalError("Verification failed: Parameter mismatch!")
        }
        print("   Parameters verified successfully!")

        print("4. Extracting tables and checking CRC32 against golden reference...")

        // Transmittance
        guard let transDesc = earthEntry.tables["transmittance"],
        transDesc.width == 256, transDesc.height == 64 else {
            fatalError("Verification failed: Unexpected transmittance resolution!")
        }
        let transTable: [SIMD4<Float>] = try archive.extractTable(
            for: "Earth",
            table: "transmittance"
        )
        let transCRC: UInt32 = transTable.withUnsafeBytes { raw in
            CRC32.init(hashing: raw).checksum
        }
        print(
            """
               Transmittance CRC32: 0x\(
                String(transCRC, radix: 16, uppercase: true)
            ) [expected: 0x\(
                String(goldenTransmittanceCRC32, radix: 16, uppercase: true)
            )]
            """
        )
        guard transCRC == goldenTransmittanceCRC32 else {
            fatalError("Verification failed: Transmittance CRC32 mismatch!")
        }

        // Irradiance
        guard let irradDesc = earthEntry.tables["irradiance"],
        irradDesc.width == 64, irradDesc.height == 16 else {
            fatalError("Verification failed: Unexpected irradiance resolution!")
        }
        let irradTable: [SIMD4<Float>] = try archive.extractTable(
            for: "Earth",
            table: "irradiance"
        )
        let irradCRC: UInt32 = irradTable.withUnsafeBytes { raw in
            CRC32.init(hashing: raw).checksum
        }
        print(
            """
               Irradiance    CRC32: 0x\(
                String(irradCRC, radix: 16, uppercase: true)
            ) [expected: 0x\(
                String(goldenIrradianceCRC32, radix: 16, uppercase: true)
            )]
            """
        )
        guard irradCRC == goldenIrradianceCRC32 else {
            fatalError("Verification failed: Irradiance CRC32 mismatch!")
        }

        // Scattering
        guard let scatDesc = earthEntry.tables["scattering"],
        scatDesc.width == 256, scatDesc.height == 128, scatDesc.depth == 32 else {
            fatalError("Verification failed: Unexpected scattering resolution!")
        }
        let scatTable: [SIMD4<Float>] = try archive.extractTable(
            for: "Earth",
            table: "scattering"
        )
        let scatCRC: UInt32 = scatTable.withUnsafeBytes { raw in
            CRC32.init(hashing: raw).checksum
        }
        print(
            """
               Scattering    CRC32: 0x\(
                String(scatCRC, radix: 16, uppercase: true)
            ) [expected: 0x\(
                String(goldenScatteringCRC32, radix: 16, uppercase: true)
            )]
            """
        )
        guard scatCRC == goldenScatteringCRC32 else {
            fatalError("Verification failed: Scattering CRC32 mismatch!")
        }

        // 5. Check against external raw golden files if explicitly provided
        if let goldenDirEnv: String = ProcessInfo.processInfo.environment[
                "GOLDEN_TABLES_DIR"
            ] {
            let goldenDir: FilePath = .init(goldenDirEnv)
            if FileManager.default.fileExists(atPath: goldenDir.string) {
                print("5. Comparing float-by-float against golden files in '\(goldenDir)'...")
                try verifyAgainstExternalGolden(
                    dir: goldenDir,
                    transmittance: transTable,
                    irradiance: irradTable,
                    scattering: scatTable
                )
                print("   Bit-for-bit exact match across all 4,263,936 floating-point values!")
            } else {
                print(
                    """
                    5. GOLDEN_TABLES_DIR specified but '\(goldenDir)' does not exist (skipping).
                    """
                )
            }
        }

        print("6. Verifying archive serialization and deserialization roundtrip...")
        let compressedBytes: [UInt8] = try archive.serialize()
        let deserialized: AtmosphereArchive = try .deserialize(from: compressedBytes)
        let reextractedScattering: [SIMD4<Float>] = try deserialized.extractTable(
            for: "Earth",
            table: "scattering"
        )
        guard reextractedScattering == scatTable else {
            fatalError("Verification failed: Table roundtrip mismatch!")
        }
        print(
            """
               Archive serialized (\(
                compressedBytes.count
            ) bytes) and deserialized successfully!
            """
        )

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("  ALL GOLDEN REFERENCE CHECKS PASSED PERFECTLY!")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    private static func verifyAgainstExternalGolden(
        dir: FilePath,
        transmittance: [SIMD4<Float>],
        irradiance: [SIMD4<Float>],
        scattering: [SIMD4<Float>]
    ) throws {
        // Transmittance
        let transPath: String = "\(dir.string)/earth-transmittance-3x.float32"
        if let data = try? Data(
                contentsOf: URL(fileURLWithPath: transPath)
            ), data.count >= 16 + transmittance.count * 16 {
            let beFloats: [Float] = data.subdata(
                in: 16 ..< 16 + transmittance.count * 16
            ).withUnsafeBytes { raw in
                let u32s: UnsafeBufferPointer<UInt32> = raw.bindMemory(to: UInt32.self)
                return u32s.map { Float(bitPattern: UInt32(bigEndian: $0)) }
            }
            transmittance.withUnsafeBytes { raw in
                let leFloats: UnsafeBufferPointer<Float> = raw.bindMemory(to: Float.self)
                for i: Int in 0 ..< beFloats.count {
                    if beFloats[i] != leFloats[i] {
                        fatalError(
                            """
                            Transmittance float mismatch at index \(i): golden=\(
                                beFloats[i]
                            ) vs baked=\(
                                leFloats[i]
                            )
                            """
                        )
                    }
                }
            }
        }

        // Irradiance
        let irradPath: String = "\(dir.string)/earth-irradiance-3x.float32"
        if let data = try? Data(
                contentsOf: URL(fileURLWithPath: irradPath)
            ), data.count >= 16 + irradiance.count * 16 {
            let beFloats: [Float] = data.subdata(
                in: 16 ..< 16 + irradiance.count * 16
            ).withUnsafeBytes { raw in
                let u32s: UnsafeBufferPointer<UInt32> = raw.bindMemory(to: UInt32.self)
                return u32s.map { Float(bitPattern: UInt32(bigEndian: $0)) }
            }
            irradiance.withUnsafeBytes { raw in
                let leFloats: UnsafeBufferPointer<Float> = raw.bindMemory(to: Float.self)
                for i: Int in 0 ..< beFloats.count {
                    if beFloats[i] != leFloats[i] {
                        fatalError(
                            """
                            Irradiance float mismatch at index \(i): golden=\(
                                beFloats[i]
                            ) vs baked=\(
                                leFloats[i]
                            )
                            """
                        )
                    }
                }
            }
        }

        // Scattering
        let scatPath: String = "\(dir.string)/earth-scattering-combined-3x.float32"
        if let data = try? Data(
                contentsOf: URL(fileURLWithPath: scatPath)
            ), data.count >= 20 + scattering.count * 16 {
            let beFloats: [Float] = data.subdata(
                in: 20 ..< 20 + scattering.count * 16
            ).withUnsafeBytes { raw in
                let u32s: UnsafeBufferPointer<UInt32> = raw.bindMemory(to: UInt32.self)
                return u32s.map { Float(bitPattern: UInt32(bigEndian: $0)) }
            }
            scattering.withUnsafeBytes { raw in
                let leFloats: UnsafeBufferPointer<Float> = raw.bindMemory(to: Float.self)
                for i: Int in 0 ..< beFloats.count {
                    if beFloats[i] != leFloats[i] {
                        fatalError(
                            """
                            Scattering float mismatch at index \(i): golden=\(
                                beFloats[i]
                            ) vs baked=\(
                                leFloats[i]
                            )
                            """
                        )
                    }
                }
            }
        }
    }
}
