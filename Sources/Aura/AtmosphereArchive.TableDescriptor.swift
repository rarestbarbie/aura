public import Ion

extension AtmosphereArchive {
    public struct TableDescriptor: Sendable, Equatable {
        public var width: Int
        public var height: Int
        public var depth: Int?
        public var offset: Int
        public var length: Int

        public init(
            width: Int,
            height: Int,
            depth: Int? = nil,
            offset: Int,
            length: Int
        ) {
            self.width = width
            self.height = height
            self.depth = depth
            self.offset = offset
            self.length = length
        }
    }
}

extension AtmosphereArchive.TableDescriptor {
    @frozen public enum CodingKey: String, IonSymbolizable {
        case width
        case height
        case depth
        case offset
        case length
    }
}

extension AtmosphereArchive.TableDescriptor: IonEncodableStruct {
    public func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.width] = self.width
        ion[.height] = self.height
        ion[.depth] = self.depth
        ion[.offset] = self.offset
        ion[.length] = self.length
    }
}

extension AtmosphereArchive.TableDescriptor: IonDecodableStruct {
    public init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        self.init(
            width: try ion[.width].decode(),
            height: try ion[.height].decode(),
            depth: try ion[.depth]?.decode(),
            offset: try ion[.offset].decode(),
            length: try ion[.length].decode()
        )
    }
}
