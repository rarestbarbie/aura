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
        help: "Atmospheric preset to bake: 'Earth', 'Venus', 'Mars', or 'Titan'."
    )
    var preset: String?

    @Flag(
        name: .long,
        help: "Bake all standard planetary presets (Earth, Venus, Mars, Titan) into a single archive."
    )
    var all: Bool = false

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
        help: "Output file path (e.g. 'atmosphere.bin.gz') or directory to write archive to."
    )
    var output: String?

    func run() throws {
        if self.all {
            let configs: [AtmosphereConfig] = [.earth, .venus, .mars, .titan]
            let outString: String = self.output ?? "Public/Atmospheres/atmospheres.bin.gz"
            let outPath: FilePath = .init(outString)
            let parent: FilePath = outPath.removingLastComponent()
            if !parent.isEmpty {
                try FilePath.Directory(path: parent).create()
            }
            print("Baking atmosphere archive for all planets (Earth, Venus, Mars, Titan) (detail: \(self.detail)) to '\(outString)'...")
            try AtmosphereBaker.bake(configs: configs, detail: self.detail, to: outPath)
            print("Successfully baked atmospheres archive to '\(outString)'!")
            return
        }

        let atmosphereConfig: AtmosphereConfig
        if let configPathString = self.config {
            let configPath: FilePath = .init(configPathString)
            print("Loading atmospheric configuration from '\(configPathString)'...")
            atmosphereConfig = try AtmosphereConfig.load(from: configPath)
        } else {
            let presetName: String = self.preset ?? "Earth"
            switch presetName {
            case "Earth":
                atmosphereConfig = .earth
            case "Venus":
                atmosphereConfig = .venus
            case "Mars":
                atmosphereConfig = .mars
            case "Titan":
                atmosphereConfig = .titan
            default:
                print("Unknown preset '\(presetName)'. Available presets: Earth, Venus, Mars, Titan")
                throw ExitCode.failure
            }
        }

        let outString: String = self.output ?? "Public/\(atmosphereConfig.name)/Atmosphere"
        let outPath: FilePath = .init(outString)

        print("Baking atmosphere for \(atmosphereConfig.name) (detail: \(self.detail)) to '\(outString)'...")
        if outString.hasSuffix(".bin.gz") || outString.hasSuffix(".gz") {
            let parent: FilePath = outPath.removingLastComponent()
            if !parent.isEmpty {
                try FilePath.Directory(path: parent).create()
            }
            try AtmosphereBaker.bake(configs: [atmosphereConfig], detail: self.detail, to: outPath)
        } else {
            try AtmosphereBaker.bake(config: atmosphereConfig, detail: self.detail, to: outPath)
        }
        print("Successfully baked atmosphere archive for \(atmosphereConfig.name) to '\(outString)'!")
    }
}
