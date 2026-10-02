extension AtmosphereArchive {
    public struct Manifest: Sendable, Codable, Equatable {
        public var version: UInt32
        public var planets: [String: PlanetEntry]

        public init(
            version: UInt32 = AtmosphereArchive.currentVersion,
            planets: [String: PlanetEntry]
        ) {
            self.version = version
            self.planets = planets
        }
    }
}
