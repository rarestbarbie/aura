extension TableCompression {
    public enum Error: Swift.Error, Sendable {
        case decompressedSizeMismatch(expected: Int, actual: Int)
    }
}
