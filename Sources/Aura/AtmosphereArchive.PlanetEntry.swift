extension AtmosphereArchive {
    public struct PlanetEntry: Sendable, Codable, Equatable {
        public var parameters: AtmosphereParameters
        public var tables: [String: TableDescriptor]

        public init(parameters: AtmosphereParameters, tables: [String: TableDescriptor]) {
            self.parameters = parameters
            self.tables = tables
        }
    }
}
