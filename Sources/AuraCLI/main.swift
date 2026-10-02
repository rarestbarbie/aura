import ArgumentParser
import Aura
import SystemPackage

@main
struct AuraCLI: ParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
            commandName: "aura",
            abstract: "Precomputes atmospheric scattering lookup tables for planetary rendering."
        )
    }

    @Option(
        name: .shortAndLong,
        help: "Atmospheric preset to bake: 'earth', 'venus', 'mars', or 'titan'."
    )
    var preset: String?

    @Option(
        name: .shortAndLong,
        help: "Path to an Ion (.ion) or JSON (.json) atmospheric configuration file."
    )
    var config: String?

    @Option(
        name: .shortAndLong,
        help: "The level of detail for precomputed tables (1 to 5). Higher detail increases table resolution."
    )
    var detail: Int = 3

    @Option(
        name: .shortAndLong,
        help: "Directory to write output tables (transmittance.bin, scattering.bin, irradiance.bin, parameters.json) to."
    )
    var output: String?

    func run() throws {
        let atmosphereConfig: AtmosphereConfig
        if let configPathString = self.config {
            let configPath: FilePath = .init(configPathString)
            print("Loading atmospheric configuration from '\(configPathString)'...")
            atmosphereConfig = try AtmosphereConfig.load(from: configPath)
        } else {
            let presetName: String = self.preset?.lowercased() ?? "earth"
            switch presetName {
            case "earth":
                atmosphereConfig = .earth
            case "venus":
                atmosphereConfig = .venus
            case "mars":
                atmosphereConfig = .mars
            case "titan":
                atmosphereConfig = .titan
            default:
                print("Unknown preset '\(presetName)'. Available presets: earth, venus, mars, titan")
                throw ExitCode.failure
            }
        }

        let outDir: String = self.output ?? "Public/\(atmosphereConfig.name)/Atmosphere"
        let outPath: FilePath = .init(outDir)

        print("Baking atmosphere for \(atmosphereConfig.name) (detail: \(self.detail)) to '\(outDir)'...")
        try AtmosphereBaker.bake(config: atmosphereConfig, detail: self.detail, to: outPath)
        print("Successfully baked atmospheric scattering tables to '\(outDir)'!")
    }
}
