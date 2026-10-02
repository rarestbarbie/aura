import CZlib

public enum TableCompressionError: Error, Sendable {
    case decompressedSizeMismatch(expected: Int, actual: Int)
    case zlibInitializationFailed(Int32)
    case decompressionFailed(Int32)
}

public enum TableCompression {
    /// Applies PNG Up filtering and 16-plane byte shuffling to a 2D or 3D buffer.
    public static func filterAndShuffle(
        raw: UnsafeRawBufferPointer,
        width: Int,
        height: Int,
        depth: Int = 1,
        bpp: Int = 16
    ) -> [UInt8] {
        let numPixels: Int = width * height * depth
        let totalBytes: Int = numPixels * bpp
        precondition(raw.count >= totalBytes, "Raw buffer is smaller than width * height * depth * bpp")

        let rawBytes: UnsafePointer<UInt8> = raw.baseAddress!.assumingMemoryBound(to: UInt8.self)

        // 1. PNG Up filter along Y within each slice Z
        let rowBytes: Int = width * bpp
        var filtered: [UInt8] = .init(repeating: 0, count: totalBytes)

        filtered.withUnsafeMutableBufferPointer { filteredPtr in
            for z: Int in 0 ..< depth {
                let sliceOffset: Int = z * height * rowBytes

                // Row 0 of this slice: unchanged
                for b: Int in 0 ..< rowBytes {
                    filteredPtr[sliceOffset + b] = rawBytes[sliceOffset + b]
                }

                // Rows 1 ..< height: difference from preceding row
                for y: Int in 1 ..< height {
                    let rowOffset: Int = sliceOffset + y * rowBytes
                    let prevOffset: Int = rowOffset - rowBytes
                    for b: Int in 0 ..< rowBytes {
                        filteredPtr[rowOffset + b] = rawBytes[rowOffset + b] &- rawBytes[prevOffset + b]
                    }
                }
            }
        }

        // 2. Byte shuffle: transpose from (numPixels, bpp) to (bpp, numPixels)
        var shuffled: [UInt8] = .init(repeating: 0, count: totalBytes)
        filtered.withUnsafeBufferPointer { filteredPtr in
            shuffled.withUnsafeMutableBufferPointer { shuffledPtr in
                for p: Int in 0 ..< bpp {
                    let planeOffset: Int = p * numPixels
                    for i: Int in 0 ..< numPixels {
                        shuffledPtr[planeOffset + i] = filteredPtr[i * bpp + p]
                    }
                }
            }
        }

        return shuffled
    }

    /// Applies PNG Up filtering and 16-plane byte shuffling to a `SIMD4<Float>` texel buffer.
    public static func filterAndShuffle(
        simd4: [SIMD4<Float>],
        width: Int,
        height: Int,
        depth: Int = 1
    ) -> [UInt8] {
        simd4.withUnsafeBytes { raw in
            filterAndShuffle(raw: raw, width: width, height: height, depth: depth, bpp: 16)
        }
    }

    /// Inverts byte plane shuffling and PNG Up filtering on a preprocessed buffer.
    public static func unshuffleAndUnfilter(
        shuffled: [UInt8],
        width: Int,
        height: Int,
        depth: Int = 1,
        bpp: Int = 16
    ) -> [UInt8] {
        let numPixels: Int = width * height * depth
        let totalBytes: Int = numPixels * bpp
        precondition(shuffled.count >= totalBytes, "Shuffled buffer is smaller than width * height * depth * bpp")

        var output: [UInt8] = .init(repeating: 0, count: totalBytes)
        let rowBytes: Int = width * bpp

        shuffled.withUnsafeBufferPointer { shufPtr in
            output.withUnsafeMutableBufferPointer { outPtr in
                var pixelIdx: Int = 0
                for z: Int in 0 ..< depth {
                    let sliceOffset: Int = z * height * rowBytes
                    for y: Int in 0 ..< height {
                        let rowOffset: Int = sliceOffset + y * rowBytes
                        let prevOffset: Int = rowOffset - rowBytes

                        if y == 0 {
                            for x: Int in 0 ..< width {
                                let pxOffset: Int = rowOffset + x * bpp
                                for p: Int in 0 ..< bpp {
                                    outPtr[pxOffset + p] = shufPtr[p * numPixels + pixelIdx]
                                }
                                pixelIdx += 1
                            }
                        } else {
                            for x: Int in 0 ..< width {
                                let pxOffset: Int = rowOffset + x * bpp
                                let prevPx: Int = prevOffset + x * bpp
                                for p: Int in 0 ..< bpp {
                                    outPtr[pxOffset + p] = outPtr[prevPx + p] &+ shufPtr[p * numPixels + pixelIdx]
                                }
                                pixelIdx += 1
                            }
                        }
                    }
                }
            }
        }

        return output
    }

    /// Inverts byte plane shuffling and PNG Up filtering on a preprocessed buffer returning `SIMD4<Float>` texels.
    public static func unshuffleAndUnfilter(
        shuffled: [UInt8],
        width: Int,
        height: Int,
        depth: Int = 1
    ) -> [SIMD4<Float>] {
        let bytes: [UInt8] = unshuffleAndUnfilter(shuffled: shuffled, width: width, height: height, depth: depth, bpp: 16)
        let numPixels: Int = width * height * depth
        return bytes.withUnsafeBytes { raw in
            let bound: UnsafeBufferPointer<SIMD4<Float>> = raw.bindMemory(to: SIMD4<Float>.self)
            return .init(bound.prefix(numPixels))
        }
    }

    /// Compresses data using Gzip (deflate).
    public static func deflate(_ data: [UInt8], level: Int32 = 6) -> [UInt8] {
        Gzip.deflate(data, level: level)
    }

    /// Decompresses data using Gzip (inflate).
    public static func inflate(_ data: [UInt8], expectedCapacity: Int = 0) throws -> [UInt8] {
        try Gzip.inflate(data, expectedCapacity: expectedCapacity)
    }

    /// Compresses a 2D or 3D volume buffer using PNG Up filtering,
    /// byte-plane shuffling, and Gzip compression.
    public static func compress(
        raw: UnsafeRawBufferPointer,
        width: Int,
        height: Int,
        depth: Int = 1,
        bpp: Int = 16
    ) -> [UInt8] {
        let shuffled: [UInt8] = filterAndShuffle(raw: raw, width: width, height: height, depth: depth, bpp: bpp)
        return deflate(shuffled, level: 6)
    }

    /// Compresses a buffer of `SIMD4<Float>` texels.
    public static func compress(
        simd4: [SIMD4<Float>],
        width: Int,
        height: Int,
        depth: Int = 1
    ) -> [UInt8] {
        simd4.withUnsafeBytes { raw in
            compress(raw: raw, width: width, height: height, depth: depth, bpp: 16)
        }
    }

    /// Decompresses an archive back into raw bytes, inverting byte shuffling and Up filtering.
    public static func decompress(
        archive: [UInt8],
        width: Int,
        height: Int,
        depth: Int = 1,
        bpp: Int = 16
    ) throws -> [UInt8] {
        let numPixels: Int = width * height * depth
        let totalBytes: Int = numPixels * bpp

        let shuffled: [UInt8] = try inflate(archive, expectedCapacity: totalBytes)
        guard shuffled.count == totalBytes else {
            throw TableCompressionError.decompressedSizeMismatch(
                expected: totalBytes,
                actual: shuffled.count
            )
        }

        return unshuffleAndUnfilter(shuffled: shuffled, width: width, height: height, depth: depth, bpp: bpp)
    }

    /// Decompresses an archive directly into an array of `SIMD4<Float>` texels.
    public static func decompress(
        archive: [UInt8],
        width: Int,
        height: Int,
        depth: Int = 1
    ) throws -> [SIMD4<Float>] {
        let bytes: [UInt8] = try decompress(archive: archive, width: width, height: height, depth: depth, bpp: 16)
        let numPixels: Int = width * height * depth
        return bytes.withUnsafeBytes { raw in
            let bound: UnsafeBufferPointer<SIMD4<Float>> = raw.bindMemory(to: SIMD4<Float>.self)
            return .init(bound.prefix(numPixels))
        }
    }
}

enum Gzip {
    static func deflate(_ data: [UInt8], level: Int32 = 6) -> [UInt8] {
        var stream: z_stream = .init()
        let retInit: Int32 = deflateInit2_(
            &stream,
            level,
            Z_DEFLATED,
            31, // 16 + 15 enables Gzip format
            8,
            Z_DEFAULT_STRATEGY,
            ZLIB_VERSION,
            Int32(MemoryLayout<z_stream>.size)
        )
        guard retInit == Z_OK else {
            fatalError("Failed to initialize zlib deflate (code \(retInit))")
        }
        defer { deflateEnd(&stream) }

        let chunkSize: Int = 65536
        var output: [UInt8] = []
        output.reserveCapacity(data.count / 2)

        data.withUnsafeBytes { rawIn in
            stream.next_in = UnsafeMutablePointer<Bytef>(mutating: rawIn.bindMemory(to: Bytef.self).baseAddress)
            stream.avail_in = uInt(data.count)

            var buffer: [UInt8] = .init(repeating: 0, count: chunkSize)
            buffer.withUnsafeMutableBytes { rawOut in
                let outPtr: UnsafeMutablePointer<Bytef>? = rawOut.bindMemory(to: Bytef.self).baseAddress
                while true {
                    stream.next_out = outPtr
                    stream.avail_out = uInt(chunkSize)

                    let ret: Int32 = CZlib.deflate(&stream, Z_FINISH)
                    let produced: Int = chunkSize - Int(stream.avail_out)
                    if produced > 0 {
                        output.append(contentsOf: rawOut.prefix(produced))
                    }
                    if ret == Z_STREAM_END {
                        break
                    }
                }
            }
        }
        return output
    }

    static func inflate(_ data: [UInt8], expectedCapacity: Int = 0) throws -> [UInt8] {
        var stream: z_stream = .init()
        let retInit: Int32 = inflateInit2_(
            &stream,
            31, // 16 + 15 enables Gzip format
            ZLIB_VERSION,
            Int32(MemoryLayout<z_stream>.size)
        )
        guard retInit == Z_OK else {
            throw TableCompressionError.zlibInitializationFailed(retInit)
        }
        defer { inflateEnd(&stream) }

        let chunkSize: Int = 65536
        var output: [UInt8] = []
        output.reserveCapacity(expectedCapacity > 0 ? expectedCapacity : data.count * 2)

        try data.withUnsafeBytes { rawIn in
            stream.next_in = UnsafeMutablePointer<Bytef>(mutating: rawIn.bindMemory(to: Bytef.self).baseAddress)
            stream.avail_in = uInt(data.count)

            var buffer: [UInt8] = .init(repeating: 0, count: chunkSize)
            try buffer.withUnsafeMutableBytes { rawOut in
                let outPtr: UnsafeMutablePointer<Bytef>? = rawOut.bindMemory(to: Bytef.self).baseAddress
                while true {
                    stream.next_out = outPtr
                    stream.avail_out = uInt(chunkSize)

                    let ret: Int32 = CZlib.inflate(&stream, Z_NO_FLUSH)
                    let produced: Int = chunkSize - Int(stream.avail_out)
                    if produced > 0 {
                        output.append(contentsOf: rawOut.prefix(produced))
                    }
                    if ret == Z_STREAM_END {
                        break
                    }
                    if ret != Z_OK {
                        throw TableCompressionError.decompressionFailed(ret)
                    }
                }
            }
        }
        return output
    }
}
