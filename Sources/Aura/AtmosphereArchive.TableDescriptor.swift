extension AtmosphereArchive {
    public struct TableDescriptor: Sendable, Codable, Equatable {
        public var width: Int
        public var height: Int
        public var depth: Int?
        public var offset: Int
        public var length: Int

        public init(width: Int, height: Int, depth: Int? = nil, offset: Int, length: Int) {
            self.width = width
            self.height = height
            self.depth = depth
            self.offset = offset
            self.length = length
        }
    }
}
