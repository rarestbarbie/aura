import CZlib

extension TableCompression {
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
                        guard ret == Z_OK || ret == Z_BUF_ERROR else {
                            fatalError("zlib deflate failed with code \(ret)")
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
                throw TableCompression.Error.zlibInitializationFailed(retInit)
            }
            defer { inflateEnd(&stream) }

            let chunkSize: Int = 65536
            var output: [UInt8] = []
            if expectedCapacity > 0 {
                output.reserveCapacity(expectedCapacity)
            } else {
                output.reserveCapacity(data.count * 2)
            }

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
                        guard ret == Z_OK else {
                            throw TableCompression.Error.decompressionFailed(ret)
                        }
                    }
                }
            }

            return output
        }
    }
}
