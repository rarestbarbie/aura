extension TableCompression {
    public enum Error: Swift.Error, Sendable {
        case decompressedSizeMismatch(expected: Int, actual: Int)
        case zlibInitializationFailed(Int32)
        case decompressionFailed(Int32)
    }
}

public typealias TableCompressionError = TableCompression.Error
