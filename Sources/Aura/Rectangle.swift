struct Rectangle<T>: Equatable where T: SIMDScalar {
    var storage: SIMD4<T>

    var a: Vector2<T> {
        get {
            return .init(self.storage.x, self.storage.y)
        }
        set(a) {
            self.storage.x = a.x
            self.storage.y = a.y
        }
    }
    var b: Vector2<T> {
        get {
            return .init(self.storage.z, self.storage.w)
        }
        set(b) {
            self.storage.z = b.x
            self.storage.w = b.y
        }
    }

    init(_ a: Vector2<T>, _ b: Vector2<T>) {
        self.init(.init(a.x, a.y, b.x, b.y))
    }

    init(_ storage: SIMD4<T>) {
        self.storage = storage
    }

    func map<Result>(_ transform: (T) throws -> Result) rethrows -> Rectangle<Result>
        where Result: SIMDScalar {
        return  .init(
            .init(
                try transform(self.storage.x),
                try transform(self.storage.y),
                try transform(self.storage.z),
                try transform(self.storage.w)
            )
        )
    }
}
extension Rectangle where T: FixedWidthInteger {
    static var zero: Rectangle<T> {
        return .init(.zero)
    }
    var size: Vector2<T> {
        return self.b &- self.a
    }
}
extension Rectangle where T: FloatingPoint {
    static var zero: Rectangle<T> {
        return .init(.zero)
    }
    var size: Vector2<T> {
        return self.b - self.a
    }
}
extension Rectangle where T: FloatingPoint & ExpressibleByFloatLiteral {
    var midpoint: Vector2<T> {
        return 0.5 * (self.a + self.b)
    }
}


extension Rectangle where T: BinaryInteger {
    static func cast<Source>(_ v: Rectangle<Source>) -> Self where Source: BinaryFloatingPoint {
        return v.map(T.init(_:))
    }
    static func cast<Source>(_ v: Rectangle<Source>) -> Self where Source: BinaryInteger {
        return v.map(T.init(_:))
    }
}
extension Rectangle where T: FloatingPoint {
    static func cast<Source>(_ v: Rectangle<Source>) -> Self where Source: BinaryInteger {
        return v.map(T.init(_:))
    }
}
extension Rectangle where T: BinaryFloatingPoint {
    static func cast<Source>(_ v: Rectangle<Source>) -> Self where Source: BinaryFloatingPoint {
        return v.map(T.init(_:))
    }
}
