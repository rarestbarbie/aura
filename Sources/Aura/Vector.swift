#if canImport(Darwin)
import func Darwin.atan2
#elseif canImport(Glibc)
import func Glibc.atan2
#elseif canImport(Musl)
import func Musl.atan2
#endif

infix operator <> : MultiplicationPrecedence // dot product
infix operator >< : MultiplicationPrecedence // cross product
infix operator &<> : MultiplicationPrecedence // wrapping dot product
infix operator &>< : MultiplicationPrecedence // wrapping cross product

infix operator ~~ : ComparisonPrecedence     // distance test
infix operator !~ : ComparisonPrecedence     // distance test

// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 15)

extension FixedWidthInteger {
    // rounds up to the next power of two, with 0 rounding up to 1.
    // numbers that are already powers of two return themselves
    @inline(__always) var nextPowerOfTwo: Self {
        1 &<< (Self.bitWidth &- (self &- 1).leadingZeroBitCount)
    }

    @inline(__always) var isPowerOfTwo: Bool {
        self > 0 && self & (self &- 1) == 0
    }
}
extension FloatingPoint {
    mutating func clip(to interval: ClosedRange<Self>) {
        self = self.clipped(to: interval)
    }

    func clipped(to interval: ClosedRange<Self>) -> Self {
        return max(interval.lowerBound, min(self, interval.upperBound))
    }

    static func interpolate(_ a: Self, _ b: Self, by t: Self) -> Self {
        return a.addingProduct(a, -t).addingProduct(b, t)
    }
}


// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 54)
struct Vector2<Scalar>: Hashable, Codable, CustomStringConvertible where Scalar: SIMDScalar {
    var storage: SIMD2<Scalar>

    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 59)
    var x: Scalar {
        get {
            self.storage.x
        }
        set(x) {
            self.storage.x = x
        }
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 59)
    var y: Scalar {
        get {
            self.storage.y
        }
        set(y) {
            self.storage.y = y
        }
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 71)

    var tuple: (Scalar, Scalar) {
        (self.x, self.y)
    }

    var description: String {
        "\(self.tuple)"
    }

    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 97)

    subscript(index: Int) -> Scalar {
        self.storage[index]
    }

    init(repeating repeatedValue: Scalar) {
        self.init(.init(repeatedValue, repeatedValue))
    }

    init(_ x: Scalar, _ y: Scalar) {
        self.init(.init(x, y))
    }

    init(_ storage: SIMD2<Scalar>) {
        self.storage = storage
    }

    func map<Result>(_ transform: (Scalar) throws -> Result) rethrows -> Vector2<Result>
        where Result: SIMDScalar {
        return .init(try transform(self.x), try transform(self.y))
    }

    // Codable
    enum CodingKeys: CodingKey {
        case x, y
    }

    init(from decoder: Decoder) throws {
        let serialized: KeyedDecodingContainer<CodingKeys> =
        try decoder.container(keyedBy: CodingKeys.self)
        // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 135)
        let x: Scalar = try serialized.decode(Scalar.self, forKey: .x)
        // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 135)
        let y: Scalar = try serialized.decode(Scalar.self, forKey: .y)
        // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 137)

        self.init(x, y)
    }

    func encode(to encoder: Encoder) throws {
        var serialized: KeyedEncodingContainer<CodingKeys> =
        encoder.container(keyedBy: CodingKeys.self)
        // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 146)
        try serialized.encode(self.x, forKey: .x)
        // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 146)
        try serialized.encode(self.y, forKey: .y)
        // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 148)
    }
}

extension Vector2 where Scalar: Comparable {
    static func min(_ a: Self, _ b: Self) -> Self {
        .init(Swift.min(a.x, b.x), Swift.min(a.y, b.y))
    }
    static func max(_ a: Self, _ b: Self) -> Self {
        .init(Swift.max(a.x, b.x), Swift.max(a.y, b.y))
    }
}

extension Vector2 where Scalar: BinaryInteger {
    static func cast<T>(_ v: Vector2<T>) -> Self where T: BinaryFloatingPoint {
        return v.map(Scalar.init(_:))
    }
    static func cast<T>(_ v: Vector2<T>) -> Self where T: BinaryInteger {
        return v.map(Scalar.init(_:))
    }
}
extension Vector2 where Scalar: FloatingPoint {
    static func cast<Source>(_ v: Vector2<Source>) -> Self where Source: BinaryInteger {
        return v.map(Scalar.init(_:))
    }
}
extension Vector2 where Scalar: BinaryFloatingPoint {
    static func cast<Source>(_ v: Vector2<Source>) -> Self where Source: BinaryFloatingPoint {
        return v.map(Scalar.init(_:))
    }
}

extension Vector2 where Scalar: FixedWidthInteger {
    static var zero: Vector2<Scalar> {
        return .init(.zero)
    }

    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 204)
    static func &<< (lhs: Vector2<Scalar>, rhs: Vector2<Scalar>)
    -> Vector2<Scalar> {
        return .init(lhs.storage &<< rhs.storage)
    }
    static func &<< (lhs: Vector2<Scalar>, rhs: Scalar)
    -> Vector2<Scalar> {
        return .init(lhs.storage &<< rhs)
    }
    static func &<< (lhs: Scalar, rhs: Vector2<Scalar>)
    -> Vector2<Scalar> {
        return .init(lhs &<< rhs.storage)
    }

    static func &<<= (lhs: inout Vector2<Scalar>, rhs: Vector2<Scalar>) {
        lhs.storage &<<= rhs.storage
    }
    static func &<<= (lhs: inout Vector2<Scalar>, rhs: Scalar) {
        lhs.storage &<<= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 204)
    static func &>> (lhs: Vector2<Scalar>, rhs: Vector2<Scalar>)
    -> Vector2<Scalar> {
        return .init(lhs.storage &>> rhs.storage)
    }
    static func &>> (lhs: Vector2<Scalar>, rhs: Scalar)
    -> Vector2<Scalar> {
        return .init(lhs.storage &>> rhs)
    }
    static func &>> (lhs: Scalar, rhs: Vector2<Scalar>)
    -> Vector2<Scalar> {
        return .init(lhs &>> rhs.storage)
    }

    static func &>>= (lhs: inout Vector2<Scalar>, rhs: Vector2<Scalar>) {
        lhs.storage &>>= rhs.storage
    }
    static func &>>= (lhs: inout Vector2<Scalar>, rhs: Scalar) {
        lhs.storage &>>= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 204)
    static func &+ (lhs: Vector2<Scalar>, rhs: Vector2<Scalar>)
    -> Vector2<Scalar> {
        return .init(lhs.storage &+ rhs.storage)
    }
    static func &+ (lhs: Vector2<Scalar>, rhs: Scalar)
    -> Vector2<Scalar> {
        return .init(lhs.storage &+ rhs)
    }
    static func &+ (lhs: Scalar, rhs: Vector2<Scalar>)
    -> Vector2<Scalar> {
        return .init(lhs &+ rhs.storage)
    }

    static func &+= (lhs: inout Vector2<Scalar>, rhs: Vector2<Scalar>) {
        lhs.storage &+= rhs.storage
    }
    static func &+= (lhs: inout Vector2<Scalar>, rhs: Scalar) {
        lhs.storage &+= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 204)
    static func &- (lhs: Vector2<Scalar>, rhs: Vector2<Scalar>)
    -> Vector2<Scalar> {
        return .init(lhs.storage &- rhs.storage)
    }
    static func &- (lhs: Vector2<Scalar>, rhs: Scalar)
    -> Vector2<Scalar> {
        return .init(lhs.storage &- rhs)
    }
    static func &- (lhs: Scalar, rhs: Vector2<Scalar>)
    -> Vector2<Scalar> {
        return .init(lhs &- rhs.storage)
    }

    static func &-= (lhs: inout Vector2<Scalar>, rhs: Vector2<Scalar>) {
        lhs.storage &-= rhs.storage
    }
    static func &-= (lhs: inout Vector2<Scalar>, rhs: Scalar) {
        lhs.storage &-= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 204)
    static func &* (lhs: Vector2<Scalar>, rhs: Vector2<Scalar>)
    -> Vector2<Scalar> {
        return .init(lhs.storage &* rhs.storage)
    }
    static func &* (lhs: Vector2<Scalar>, rhs: Scalar)
    -> Vector2<Scalar> {
        return .init(lhs.storage &* rhs)
    }
    static func &* (lhs: Scalar, rhs: Vector2<Scalar>)
    -> Vector2<Scalar> {
        return .init(lhs &* rhs.storage)
    }

    static func &*= (lhs: inout Vector2<Scalar>, rhs: Vector2<Scalar>) {
        lhs.storage &*= rhs.storage
    }
    static func &*= (lhs: inout Vector2<Scalar>, rhs: Scalar) {
        lhs.storage &*= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 204)
    static func / (lhs: Vector2<Scalar>, rhs: Vector2<Scalar>)
    -> Vector2<Scalar> {
        return .init(lhs.storage / rhs.storage)
    }
    static func / (lhs: Vector2<Scalar>, rhs: Scalar)
    -> Vector2<Scalar> {
        return .init(lhs.storage / rhs)
    }
    static func / (lhs: Scalar, rhs: Vector2<Scalar>)
    -> Vector2<Scalar> {
        return .init(lhs / rhs.storage)
    }

    static func /= (lhs: inout Vector2<Scalar>, rhs: Vector2<Scalar>) {
        lhs.storage /= rhs.storage
    }
    static func /= (lhs: inout Vector2<Scalar>, rhs: Scalar) {
        lhs.storage /= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 204)
    static func % (lhs: Vector2<Scalar>, rhs: Vector2<Scalar>)
    -> Vector2<Scalar> {
        return .init(lhs.storage % rhs.storage)
    }
    static func % (lhs: Vector2<Scalar>, rhs: Scalar)
    -> Vector2<Scalar> {
        return .init(lhs.storage % rhs)
    }
    static func % (lhs: Scalar, rhs: Vector2<Scalar>)
    -> Vector2<Scalar> {
        return .init(lhs % rhs.storage)
    }

    static func %= (lhs: inout Vector2<Scalar>, rhs: Vector2<Scalar>) {
        lhs.storage %= rhs.storage
    }
    static func %= (lhs: inout Vector2<Scalar>, rhs: Scalar) {
        lhs.storage %= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 234)

    func roundedUp(exponent: Int) -> Vector2<Scalar> {
        let mask: Scalar                 = .max &<< exponent
        let truncated: SIMD2<Scalar>  = self.storage & mask
        let carry: SIMD2<Scalar> =
        SIMD2<Scalar>.zero.replacing(with: 1 &<< exponent, where: self.storage & ~mask .!= 0)
        return .init(truncated &+ carry)
    }

    var wrappingSum: Scalar {
        return self.x &+ self.y
    }
    var wrappingVolume: Scalar {
        return self.x &* self.y
    }

    static func &<> (lhs: Vector2<Scalar>, rhs: Vector2<Scalar>) -> Scalar {
        return (lhs &* rhs).wrappingSum
    }
}

extension Vector2 where Scalar: ExpressibleByIntegerLiteral {
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 262)
    static var i: Self {
        .init(1, 0)
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 262)
    static var j: Self {
        .init(0, 1)
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 268)
}

extension Vector2 where Scalar: FloatingPoint {
    static var zero: Vector2<Scalar> {
        return .init(.zero)
    }

    prefix static func - (operand: Vector2<Scalar>) -> Vector2<Scalar> {
        return .init(-operand.storage)
    }

    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 285)
    static func + (lhs: Vector2<Scalar>, rhs: Vector2<Scalar>)
    -> Vector2<Scalar> {
        return .init(lhs.storage + rhs.storage)
    }
    static func + (lhs: Vector2<Scalar>, rhs: Scalar)
    -> Vector2<Scalar> {
        return .init(lhs.storage + rhs)
    }
    static func + (lhs: Scalar, rhs: Vector2<Scalar>)
    -> Vector2<Scalar> {
        return .init(lhs + rhs.storage)
    }

    static func += (lhs: inout Vector2<Scalar>, rhs: Vector2<Scalar>) {
        lhs.storage += rhs.storage
    }
    static func += (lhs: inout Vector2<Scalar>, rhs: Scalar) {
        lhs.storage += rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 285)
    static func - (lhs: Vector2<Scalar>, rhs: Vector2<Scalar>)
    -> Vector2<Scalar> {
        return .init(lhs.storage - rhs.storage)
    }
    static func - (lhs: Vector2<Scalar>, rhs: Scalar)
    -> Vector2<Scalar> {
        return .init(lhs.storage - rhs)
    }
    static func - (lhs: Scalar, rhs: Vector2<Scalar>)
    -> Vector2<Scalar> {
        return .init(lhs - rhs.storage)
    }

    static func -= (lhs: inout Vector2<Scalar>, rhs: Vector2<Scalar>) {
        lhs.storage -= rhs.storage
    }
    static func -= (lhs: inout Vector2<Scalar>, rhs: Scalar) {
        lhs.storage -= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 285)
    static func * (lhs: Vector2<Scalar>, rhs: Vector2<Scalar>)
    -> Vector2<Scalar> {
        return .init(lhs.storage * rhs.storage)
    }
    static func * (lhs: Vector2<Scalar>, rhs: Scalar)
    -> Vector2<Scalar> {
        return .init(lhs.storage * rhs)
    }
    static func * (lhs: Scalar, rhs: Vector2<Scalar>)
    -> Vector2<Scalar> {
        return .init(lhs * rhs.storage)
    }

    static func *= (lhs: inout Vector2<Scalar>, rhs: Vector2<Scalar>) {
        lhs.storage *= rhs.storage
    }
    static func *= (lhs: inout Vector2<Scalar>, rhs: Scalar) {
        lhs.storage *= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 285)
    static func / (lhs: Vector2<Scalar>, rhs: Vector2<Scalar>)
    -> Vector2<Scalar> {
        return .init(lhs.storage / rhs.storage)
    }
    static func / (lhs: Vector2<Scalar>, rhs: Scalar)
    -> Vector2<Scalar> {
        return .init(lhs.storage / rhs)
    }
    static func / (lhs: Scalar, rhs: Vector2<Scalar>)
    -> Vector2<Scalar> {
        return .init(lhs / rhs.storage)
    }

    static func /= (lhs: inout Vector2<Scalar>, rhs: Vector2<Scalar>) {
        lhs.storage /= rhs.storage
    }
    static func /= (lhs: inout Vector2<Scalar>, rhs: Scalar) {
        lhs.storage /= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 315)

    func addingProduct(_ lhs: Vector2<Scalar>, _ rhs: Vector2<Scalar>) -> Vector2<Scalar> {
        return .init(self.storage.addingProduct(lhs.storage, rhs.storage))
    }
    func addingProduct(_ lhs: Scalar, _ rhs: Vector2<Scalar>) -> Vector2<Scalar> {
        return .init(self.storage.addingProduct(lhs, rhs.storage))
    }
    func addingProduct(_ lhs: Vector2<Scalar>, _ rhs: Scalar) -> Vector2<Scalar> {
        return .init(self.storage.addingProduct(lhs.storage, rhs))
    }
    mutating func addProduct(_ lhs: Vector2<Scalar>, _ rhs: Vector2<Scalar>) {
        self.storage.addProduct(lhs.storage, rhs.storage)
    }
    mutating func addProduct(_ lhs: Scalar, _ rhs: Vector2<Scalar>) {
        self.storage.addProduct(lhs, rhs.storage)
    }
    mutating func addProduct(_ lhs: Vector2<Scalar>, _ rhs: Scalar) {
        self.storage.addProduct(lhs.storage, rhs)
    }

    func squareRoot() -> Vector2<Scalar> {
        return .init(self.storage.squareRoot())
    }

    func rounded(_ rule: FloatingPointRoundingRule) -> Vector2<Scalar> {
        return .init(self.storage.rounded(rule))
    }
    mutating func round(_ rule: FloatingPointRoundingRule) {
        self.storage.round(rule)
    }

    static func interpolate(_ a: Vector2<Scalar>, _ b: Vector2<Scalar>, by t: Scalar)
    -> Vector2<Scalar> {
        return a.addingProduct(a, -t).addingProduct(b, t)
    }


    var sum: Scalar {
        return self.x + self.y
    }
    var volume: Scalar {
        return self.x * self.y
    }

    static func <> (lhs: Vector2<Scalar>, rhs: Vector2<Scalar>) -> Scalar {
        return (lhs * rhs).sum
    }

    var length: Scalar {
        return (self <> self).squareRoot()
    }

    mutating func normalize() {
        self /= self.length
    }
    func normalized() -> Vector2<Scalar> {
        return self / self.length
    }

    static func <  (v: Vector2<Scalar>, r: Scalar) -> Bool {
        return v <> v <  r
    }
    static func <= (v: Vector2<Scalar>, r: Scalar) -> Bool {
        return v <> v <= r
    }
    static func ~~ (v: Vector2<Scalar>, r: Scalar) -> Bool {
        return v <> v == r
    }
    static func !~ (v: Vector2<Scalar>, r: Scalar) -> Bool {
        return v <> v != r
    }
    static func >= (v: Vector2<Scalar>, r: Scalar) -> Bool {
        return v <> v >= r
    }
    static func >  (v: Vector2<Scalar>, r: Scalar) -> Bool {
        return v <> v >  r
    }
}

func wrappingAbs<Scalar>(
    _ v: Vector2<Scalar>
) -> Vector2<Scalar> where Scalar: FixedWidthInteger {
    return .init(v.storage.replacing(with: 0 &- v.storage, where: v.storage .< 0))
}
func         abs<Scalar>(_ v: Vector2<Scalar>) -> Vector2<Scalar> where Scalar: FloatingPoint {
    return .init(v.storage.replacing(with: -v.storage, where: v.storage .< 0))
}

// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 54)
struct Vector3<Scalar>: Hashable, Codable, CustomStringConvertible where Scalar: SIMDScalar {
    var storage: SIMD3<Scalar>

    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 59)
    var x: Scalar {
        get {
            self.storage.x
        }
        set(x) {
            self.storage.x = x
        }
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 59)
    var y: Scalar {
        get {
            self.storage.y
        }
        set(y) {
            self.storage.y = y
        }
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 59)
    var z: Scalar {
        get {
            self.storage.z
        }
        set(z) {
            self.storage.z = z
        }
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 71)

    var tuple: (Scalar, Scalar, Scalar) {
        (self.x, self.y, self.z)
    }

    var description: String {
        "\(self.tuple)"
    }

    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 84)
    var xy: Vector2<Scalar> {
        .init(self.x, self.y)
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 89)

    static func extend(_ body: Vector2<Scalar>, _ tail: Scalar)
    -> Vector3<Scalar> {
        .init(body.x, body.y, tail)
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 97)

    subscript(index: Int) -> Scalar {
        self.storage[index]
    }

    init(repeating repeatedValue: Scalar) {
        self.init(.init(repeatedValue, repeatedValue, repeatedValue))
    }

    init(_ x: Scalar, _ y: Scalar, _ z: Scalar) {
        self.init(.init(x, y, z))
    }

    init(_ storage: SIMD3<Scalar>) {
        self.storage = storage
    }

    func map<Result>(_ transform: (Scalar) throws -> Result) rethrows -> Vector3<Result>
        where Result: SIMDScalar {
        return .init(try transform(self.x), try transform(self.y), try transform(self.z))
    }

    // Codable
    enum CodingKeys: CodingKey {
        case x, y, z
    }

    init(from decoder: Decoder) throws {
        let serialized: KeyedDecodingContainer<CodingKeys> =
        try decoder.container(keyedBy: CodingKeys.self)
        // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 135)
        let x: Scalar = try serialized.decode(Scalar.self, forKey: .x)
        // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 135)
        let y: Scalar = try serialized.decode(Scalar.self, forKey: .y)
        // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 135)
        let z: Scalar = try serialized.decode(Scalar.self, forKey: .z)
        // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 137)

        self.init(x, y, z)
    }

    func encode(to encoder: Encoder) throws {
        var serialized: KeyedEncodingContainer<CodingKeys> =
        encoder.container(keyedBy: CodingKeys.self)
        // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 146)
        try serialized.encode(self.x, forKey: .x)
        // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 146)
        try serialized.encode(self.y, forKey: .y)
        // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 146)
        try serialized.encode(self.z, forKey: .z)
        // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 148)
    }
}

extension Vector3 where Scalar: Comparable {
    static func min(_ a: Self, _ b: Self) -> Self {
        .init(Swift.min(a.x, b.x), Swift.min(a.y, b.y), Swift.min(a.z, b.z))
    }
    static func max(_ a: Self, _ b: Self) -> Self {
        .init(Swift.max(a.x, b.x), Swift.max(a.y, b.y), Swift.max(a.z, b.z))
    }
}

extension Vector3 where Scalar: BinaryInteger {
    static func cast<T>(_ v: Vector3<T>) -> Self where T: BinaryFloatingPoint {
        return v.map(Scalar.init(_:))
    }
    static func cast<T>(_ v: Vector3<T>) -> Self where T: BinaryInteger {
        return v.map(Scalar.init(_:))
    }
}
extension Vector3 where Scalar: FloatingPoint {
    static func cast<Source>(_ v: Vector3<Source>) -> Self where Source: BinaryInteger {
        return v.map(Scalar.init(_:))
    }
}
extension Vector3 where Scalar: BinaryFloatingPoint {
    static func cast<Source>(_ v: Vector3<Source>) -> Self where Source: BinaryFloatingPoint {
        return v.map(Scalar.init(_:))
    }
}

extension Vector3 where Scalar: FixedWidthInteger {
    static var zero: Vector3<Scalar> {
        return .init(.zero)
    }

    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 204)
    static func &<< (lhs: Vector3<Scalar>, rhs: Vector3<Scalar>)
    -> Vector3<Scalar> {
        return .init(lhs.storage &<< rhs.storage)
    }
    static func &<< (lhs: Vector3<Scalar>, rhs: Scalar)
    -> Vector3<Scalar> {
        return .init(lhs.storage &<< rhs)
    }
    static func &<< (lhs: Scalar, rhs: Vector3<Scalar>)
    -> Vector3<Scalar> {
        return .init(lhs &<< rhs.storage)
    }

    static func &<<= (lhs: inout Vector3<Scalar>, rhs: Vector3<Scalar>) {
        lhs.storage &<<= rhs.storage
    }
    static func &<<= (lhs: inout Vector3<Scalar>, rhs: Scalar) {
        lhs.storage &<<= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 204)
    static func &>> (lhs: Vector3<Scalar>, rhs: Vector3<Scalar>)
    -> Vector3<Scalar> {
        return .init(lhs.storage &>> rhs.storage)
    }
    static func &>> (lhs: Vector3<Scalar>, rhs: Scalar)
    -> Vector3<Scalar> {
        return .init(lhs.storage &>> rhs)
    }
    static func &>> (lhs: Scalar, rhs: Vector3<Scalar>)
    -> Vector3<Scalar> {
        return .init(lhs &>> rhs.storage)
    }

    static func &>>= (lhs: inout Vector3<Scalar>, rhs: Vector3<Scalar>) {
        lhs.storage &>>= rhs.storage
    }
    static func &>>= (lhs: inout Vector3<Scalar>, rhs: Scalar) {
        lhs.storage &>>= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 204)
    static func &+ (lhs: Vector3<Scalar>, rhs: Vector3<Scalar>)
    -> Vector3<Scalar> {
        return .init(lhs.storage &+ rhs.storage)
    }
    static func &+ (lhs: Vector3<Scalar>, rhs: Scalar)
    -> Vector3<Scalar> {
        return .init(lhs.storage &+ rhs)
    }
    static func &+ (lhs: Scalar, rhs: Vector3<Scalar>)
    -> Vector3<Scalar> {
        return .init(lhs &+ rhs.storage)
    }

    static func &+= (lhs: inout Vector3<Scalar>, rhs: Vector3<Scalar>) {
        lhs.storage &+= rhs.storage
    }
    static func &+= (lhs: inout Vector3<Scalar>, rhs: Scalar) {
        lhs.storage &+= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 204)
    static func &- (lhs: Vector3<Scalar>, rhs: Vector3<Scalar>)
    -> Vector3<Scalar> {
        return .init(lhs.storage &- rhs.storage)
    }
    static func &- (lhs: Vector3<Scalar>, rhs: Scalar)
    -> Vector3<Scalar> {
        return .init(lhs.storage &- rhs)
    }
    static func &- (lhs: Scalar, rhs: Vector3<Scalar>)
    -> Vector3<Scalar> {
        return .init(lhs &- rhs.storage)
    }

    static func &-= (lhs: inout Vector3<Scalar>, rhs: Vector3<Scalar>) {
        lhs.storage &-= rhs.storage
    }
    static func &-= (lhs: inout Vector3<Scalar>, rhs: Scalar) {
        lhs.storage &-= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 204)
    static func &* (lhs: Vector3<Scalar>, rhs: Vector3<Scalar>)
    -> Vector3<Scalar> {
        return .init(lhs.storage &* rhs.storage)
    }
    static func &* (lhs: Vector3<Scalar>, rhs: Scalar)
    -> Vector3<Scalar> {
        return .init(lhs.storage &* rhs)
    }
    static func &* (lhs: Scalar, rhs: Vector3<Scalar>)
    -> Vector3<Scalar> {
        return .init(lhs &* rhs.storage)
    }

    static func &*= (lhs: inout Vector3<Scalar>, rhs: Vector3<Scalar>) {
        lhs.storage &*= rhs.storage
    }
    static func &*= (lhs: inout Vector3<Scalar>, rhs: Scalar) {
        lhs.storage &*= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 204)
    static func / (lhs: Vector3<Scalar>, rhs: Vector3<Scalar>)
    -> Vector3<Scalar> {
        return .init(lhs.storage / rhs.storage)
    }
    static func / (lhs: Vector3<Scalar>, rhs: Scalar)
    -> Vector3<Scalar> {
        return .init(lhs.storage / rhs)
    }
    static func / (lhs: Scalar, rhs: Vector3<Scalar>)
    -> Vector3<Scalar> {
        return .init(lhs / rhs.storage)
    }

    static func /= (lhs: inout Vector3<Scalar>, rhs: Vector3<Scalar>) {
        lhs.storage /= rhs.storage
    }
    static func /= (lhs: inout Vector3<Scalar>, rhs: Scalar) {
        lhs.storage /= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 204)
    static func % (lhs: Vector3<Scalar>, rhs: Vector3<Scalar>)
    -> Vector3<Scalar> {
        return .init(lhs.storage % rhs.storage)
    }
    static func % (lhs: Vector3<Scalar>, rhs: Scalar)
    -> Vector3<Scalar> {
        return .init(lhs.storage % rhs)
    }
    static func % (lhs: Scalar, rhs: Vector3<Scalar>)
    -> Vector3<Scalar> {
        return .init(lhs % rhs.storage)
    }

    static func %= (lhs: inout Vector3<Scalar>, rhs: Vector3<Scalar>) {
        lhs.storage %= rhs.storage
    }
    static func %= (lhs: inout Vector3<Scalar>, rhs: Scalar) {
        lhs.storage %= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 234)

    func roundedUp(exponent: Int) -> Vector3<Scalar> {
        let mask: Scalar                 = .max &<< exponent
        let truncated: SIMD3<Scalar>  = self.storage & mask
        let carry: SIMD3<Scalar> =
        SIMD3<Scalar>.zero.replacing(with: 1 &<< exponent, where: self.storage & ~mask .!= 0)
        return .init(truncated &+ carry)
    }

    var wrappingSum: Scalar {
        return self.x &+ self.y &+ self.z
    }
    var wrappingVolume: Scalar {
        return self.x &* self.y &* self.z
    }

    static func &<> (lhs: Vector3<Scalar>, rhs: Vector3<Scalar>) -> Scalar {
        return (lhs &* rhs).wrappingSum
    }
}

extension Vector3 where Scalar: ExpressibleByIntegerLiteral {
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 262)
    static var i: Self {
        .init(1, 0, 0)
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 262)
    static var j: Self {
        .init(0, 1, 0)
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 262)
    static var k: Self {
        .init(0, 0, 1)
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 268)
}

extension Vector3 where Scalar: FloatingPoint {
    static var zero: Vector3<Scalar> {
        return .init(.zero)
    }

    prefix static func - (operand: Vector3<Scalar>) -> Vector3<Scalar> {
        return .init(-operand.storage)
    }

    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 285)
    static func + (lhs: Vector3<Scalar>, rhs: Vector3<Scalar>)
    -> Vector3<Scalar> {
        return .init(lhs.storage + rhs.storage)
    }
    static func + (lhs: Vector3<Scalar>, rhs: Scalar)
    -> Vector3<Scalar> {
        return .init(lhs.storage + rhs)
    }
    static func + (lhs: Scalar, rhs: Vector3<Scalar>)
    -> Vector3<Scalar> {
        return .init(lhs + rhs.storage)
    }

    static func += (lhs: inout Vector3<Scalar>, rhs: Vector3<Scalar>) {
        lhs.storage += rhs.storage
    }
    static func += (lhs: inout Vector3<Scalar>, rhs: Scalar) {
        lhs.storage += rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 285)
    static func - (lhs: Vector3<Scalar>, rhs: Vector3<Scalar>)
    -> Vector3<Scalar> {
        return .init(lhs.storage - rhs.storage)
    }
    static func - (lhs: Vector3<Scalar>, rhs: Scalar)
    -> Vector3<Scalar> {
        return .init(lhs.storage - rhs)
    }
    static func - (lhs: Scalar, rhs: Vector3<Scalar>)
    -> Vector3<Scalar> {
        return .init(lhs - rhs.storage)
    }

    static func -= (lhs: inout Vector3<Scalar>, rhs: Vector3<Scalar>) {
        lhs.storage -= rhs.storage
    }
    static func -= (lhs: inout Vector3<Scalar>, rhs: Scalar) {
        lhs.storage -= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 285)
    static func * (lhs: Vector3<Scalar>, rhs: Vector3<Scalar>)
    -> Vector3<Scalar> {
        return .init(lhs.storage * rhs.storage)
    }
    static func * (lhs: Vector3<Scalar>, rhs: Scalar)
    -> Vector3<Scalar> {
        return .init(lhs.storage * rhs)
    }
    static func * (lhs: Scalar, rhs: Vector3<Scalar>)
    -> Vector3<Scalar> {
        return .init(lhs * rhs.storage)
    }

    static func *= (lhs: inout Vector3<Scalar>, rhs: Vector3<Scalar>) {
        lhs.storage *= rhs.storage
    }
    static func *= (lhs: inout Vector3<Scalar>, rhs: Scalar) {
        lhs.storage *= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 285)
    static func / (lhs: Vector3<Scalar>, rhs: Vector3<Scalar>)
    -> Vector3<Scalar> {
        return .init(lhs.storage / rhs.storage)
    }
    static func / (lhs: Vector3<Scalar>, rhs: Scalar)
    -> Vector3<Scalar> {
        return .init(lhs.storage / rhs)
    }
    static func / (lhs: Scalar, rhs: Vector3<Scalar>)
    -> Vector3<Scalar> {
        return .init(lhs / rhs.storage)
    }

    static func /= (lhs: inout Vector3<Scalar>, rhs: Vector3<Scalar>) {
        lhs.storage /= rhs.storage
    }
    static func /= (lhs: inout Vector3<Scalar>, rhs: Scalar) {
        lhs.storage /= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 315)

    func addingProduct(_ lhs: Vector3<Scalar>, _ rhs: Vector3<Scalar>) -> Vector3<Scalar> {
        return .init(self.storage.addingProduct(lhs.storage, rhs.storage))
    }
    func addingProduct(_ lhs: Scalar, _ rhs: Vector3<Scalar>) -> Vector3<Scalar> {
        return .init(self.storage.addingProduct(lhs, rhs.storage))
    }
    func addingProduct(_ lhs: Vector3<Scalar>, _ rhs: Scalar) -> Vector3<Scalar> {
        return .init(self.storage.addingProduct(lhs.storage, rhs))
    }
    mutating func addProduct(_ lhs: Vector3<Scalar>, _ rhs: Vector3<Scalar>) {
        self.storage.addProduct(lhs.storage, rhs.storage)
    }
    mutating func addProduct(_ lhs: Scalar, _ rhs: Vector3<Scalar>) {
        self.storage.addProduct(lhs, rhs.storage)
    }
    mutating func addProduct(_ lhs: Vector3<Scalar>, _ rhs: Scalar) {
        self.storage.addProduct(lhs.storage, rhs)
    }

    func squareRoot() -> Vector3<Scalar> {
        return .init(self.storage.squareRoot())
    }

    func rounded(_ rule: FloatingPointRoundingRule) -> Vector3<Scalar> {
        return .init(self.storage.rounded(rule))
    }
    mutating func round(_ rule: FloatingPointRoundingRule) {
        self.storage.round(rule)
    }

    static func interpolate(_ a: Vector3<Scalar>, _ b: Vector3<Scalar>, by t: Scalar)
    -> Vector3<Scalar> {
        return a.addingProduct(a, -t).addingProduct(b, t)
    }


    var sum: Scalar {
        return self.x + self.y + self.z
    }
    var volume: Scalar {
        return self.x * self.y * self.z
    }

    static func <> (lhs: Vector3<Scalar>, rhs: Vector3<Scalar>) -> Scalar {
        return (lhs * rhs).sum
    }

    var length: Scalar {
        return (self <> self).squareRoot()
    }

    mutating func normalize() {
        self /= self.length
    }
    func normalized() -> Vector3<Scalar> {
        return self / self.length
    }

    static func <  (v: Vector3<Scalar>, r: Scalar) -> Bool {
        return v <> v <  r
    }
    static func <= (v: Vector3<Scalar>, r: Scalar) -> Bool {
        return v <> v <= r
    }
    static func ~~ (v: Vector3<Scalar>, r: Scalar) -> Bool {
        return v <> v == r
    }
    static func !~ (v: Vector3<Scalar>, r: Scalar) -> Bool {
        return v <> v != r
    }
    static func >= (v: Vector3<Scalar>, r: Scalar) -> Bool {
        return v <> v >= r
    }
    static func >  (v: Vector3<Scalar>, r: Scalar) -> Bool {
        return v <> v >  r
    }
}

func wrappingAbs<Scalar>(
    _ v: Vector3<Scalar>
) -> Vector3<Scalar> where Scalar: FixedWidthInteger {
    return .init(v.storage.replacing(with: 0 &- v.storage, where: v.storage .< 0))
}
func         abs<Scalar>(_ v: Vector3<Scalar>) -> Vector3<Scalar> where Scalar: FloatingPoint {
    return .init(v.storage.replacing(with: -v.storage, where: v.storage .< 0))
}

// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 54)
struct Vector4<Scalar>: Hashable, Codable, CustomStringConvertible where Scalar: SIMDScalar {
    var storage: SIMD4<Scalar>

    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 59)
    var x: Scalar {
        get {
            self.storage.x
        }
        set(x) {
            self.storage.x = x
        }
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 59)
    var y: Scalar {
        get {
            self.storage.y
        }
        set(y) {
            self.storage.y = y
        }
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 59)
    var z: Scalar {
        get {
            self.storage.z
        }
        set(z) {
            self.storage.z = z
        }
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 59)
    var w: Scalar {
        get {
            self.storage.w
        }
        set(w) {
            self.storage.w = w
        }
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 71)

    var tuple: (Scalar, Scalar, Scalar, Scalar) {
        (self.x, self.y, self.z, self.w)
    }

    var description: String {
        "\(self.tuple)"
    }

    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 84)
    var xy: Vector2<Scalar> {
        .init(self.x, self.y)
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 84)
    var xyz: Vector3<Scalar> {
        .init(self.x, self.y, self.z)
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 89)

    static func extend(_ body: Vector3<Scalar>, _ tail: Scalar)
    -> Vector4<Scalar> {
        .init(body.x, body.y, body.z, tail)
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 97)

    subscript(index: Int) -> Scalar {
        self.storage[index]
    }

    init(repeating repeatedValue: Scalar) {
        self.init(.init(repeatedValue, repeatedValue, repeatedValue, repeatedValue))
    }

    init(_ x: Scalar, _ y: Scalar, _ z: Scalar, _ w: Scalar) {
        self.init(.init(x, y, z, w))
    }

    init(_ storage: SIMD4<Scalar>) {
        self.storage = storage
    }

    func map<Result>(_ transform: (Scalar) throws -> Result) rethrows -> Vector4<Result>
        where Result: SIMDScalar {
        return .init(
            try transform(self.x),
            try transform(self.y),
            try transform(self.z),
            try transform(self.w)
        )
    }

    // Codable
    enum CodingKeys: CodingKey {
        case x, y, z, w
    }

    init(from decoder: Decoder) throws {
        let serialized: KeyedDecodingContainer<CodingKeys> =
        try decoder.container(keyedBy: CodingKeys.self)
        // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 135)
        let x: Scalar = try serialized.decode(Scalar.self, forKey: .x)
        // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 135)
        let y: Scalar = try serialized.decode(Scalar.self, forKey: .y)
        // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 135)
        let z: Scalar = try serialized.decode(Scalar.self, forKey: .z)
        // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 135)
        let w: Scalar = try serialized.decode(Scalar.self, forKey: .w)
        // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 137)

        self.init(x, y, z, w)
    }

    func encode(to encoder: Encoder) throws {
        var serialized: KeyedEncodingContainer<CodingKeys> =
        encoder.container(keyedBy: CodingKeys.self)
        // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 146)
        try serialized.encode(self.x, forKey: .x)
        // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 146)
        try serialized.encode(self.y, forKey: .y)
        // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 146)
        try serialized.encode(self.z, forKey: .z)
        // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 146)
        try serialized.encode(self.w, forKey: .w)
        // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 148)
    }
}

extension Vector4 where Scalar: Comparable {
    static func min(_ a: Self, _ b: Self) -> Self {
        .init(
            Swift.min(a.x, b.x),
            Swift.min(a.y, b.y),
            Swift.min(a.z, b.z),
            Swift.min(a.w, b.w)
        )
    }
    static func max(_ a: Self, _ b: Self) -> Self {
        .init(
            Swift.max(a.x, b.x),
            Swift.max(a.y, b.y),
            Swift.max(a.z, b.z),
            Swift.max(a.w, b.w)
        )
    }
}

extension Vector4 where Scalar: BinaryInteger {
    static func cast<T>(_ v: Vector4<T>) -> Self where T: BinaryFloatingPoint {
        return v.map(Scalar.init(_:))
    }
    static func cast<T>(_ v: Vector4<T>) -> Self where T: BinaryInteger {
        return v.map(Scalar.init(_:))
    }
}
extension Vector4 where Scalar: FloatingPoint {
    static func cast<Source>(_ v: Vector4<Source>) -> Self where Source: BinaryInteger {
        return v.map(Scalar.init(_:))
    }
}
extension Vector4 where Scalar: BinaryFloatingPoint {
    static func cast<Source>(_ v: Vector4<Source>) -> Self where Source: BinaryFloatingPoint {
        return v.map(Scalar.init(_:))
    }
}

extension Vector4 where Scalar: FixedWidthInteger {
    static var zero: Vector4<Scalar> {
        return .init(.zero)
    }

    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 204)
    static func &<< (lhs: Vector4<Scalar>, rhs: Vector4<Scalar>)
    -> Vector4<Scalar> {
        return .init(lhs.storage &<< rhs.storage)
    }
    static func &<< (lhs: Vector4<Scalar>, rhs: Scalar)
    -> Vector4<Scalar> {
        return .init(lhs.storage &<< rhs)
    }
    static func &<< (lhs: Scalar, rhs: Vector4<Scalar>)
    -> Vector4<Scalar> {
        return .init(lhs &<< rhs.storage)
    }

    static func &<<= (lhs: inout Vector4<Scalar>, rhs: Vector4<Scalar>) {
        lhs.storage &<<= rhs.storage
    }
    static func &<<= (lhs: inout Vector4<Scalar>, rhs: Scalar) {
        lhs.storage &<<= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 204)
    static func &>> (lhs: Vector4<Scalar>, rhs: Vector4<Scalar>)
    -> Vector4<Scalar> {
        return .init(lhs.storage &>> rhs.storage)
    }
    static func &>> (lhs: Vector4<Scalar>, rhs: Scalar)
    -> Vector4<Scalar> {
        return .init(lhs.storage &>> rhs)
    }
    static func &>> (lhs: Scalar, rhs: Vector4<Scalar>)
    -> Vector4<Scalar> {
        return .init(lhs &>> rhs.storage)
    }

    static func &>>= (lhs: inout Vector4<Scalar>, rhs: Vector4<Scalar>) {
        lhs.storage &>>= rhs.storage
    }
    static func &>>= (lhs: inout Vector4<Scalar>, rhs: Scalar) {
        lhs.storage &>>= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 204)
    static func &+ (lhs: Vector4<Scalar>, rhs: Vector4<Scalar>)
    -> Vector4<Scalar> {
        return .init(lhs.storage &+ rhs.storage)
    }
    static func &+ (lhs: Vector4<Scalar>, rhs: Scalar)
    -> Vector4<Scalar> {
        return .init(lhs.storage &+ rhs)
    }
    static func &+ (lhs: Scalar, rhs: Vector4<Scalar>)
    -> Vector4<Scalar> {
        return .init(lhs &+ rhs.storage)
    }

    static func &+= (lhs: inout Vector4<Scalar>, rhs: Vector4<Scalar>) {
        lhs.storage &+= rhs.storage
    }
    static func &+= (lhs: inout Vector4<Scalar>, rhs: Scalar) {
        lhs.storage &+= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 204)
    static func &- (lhs: Vector4<Scalar>, rhs: Vector4<Scalar>)
    -> Vector4<Scalar> {
        return .init(lhs.storage &- rhs.storage)
    }
    static func &- (lhs: Vector4<Scalar>, rhs: Scalar)
    -> Vector4<Scalar> {
        return .init(lhs.storage &- rhs)
    }
    static func &- (lhs: Scalar, rhs: Vector4<Scalar>)
    -> Vector4<Scalar> {
        return .init(lhs &- rhs.storage)
    }

    static func &-= (lhs: inout Vector4<Scalar>, rhs: Vector4<Scalar>) {
        lhs.storage &-= rhs.storage
    }
    static func &-= (lhs: inout Vector4<Scalar>, rhs: Scalar) {
        lhs.storage &-= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 204)
    static func &* (lhs: Vector4<Scalar>, rhs: Vector4<Scalar>)
    -> Vector4<Scalar> {
        return .init(lhs.storage &* rhs.storage)
    }
    static func &* (lhs: Vector4<Scalar>, rhs: Scalar)
    -> Vector4<Scalar> {
        return .init(lhs.storage &* rhs)
    }
    static func &* (lhs: Scalar, rhs: Vector4<Scalar>)
    -> Vector4<Scalar> {
        return .init(lhs &* rhs.storage)
    }

    static func &*= (lhs: inout Vector4<Scalar>, rhs: Vector4<Scalar>) {
        lhs.storage &*= rhs.storage
    }
    static func &*= (lhs: inout Vector4<Scalar>, rhs: Scalar) {
        lhs.storage &*= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 204)
    static func / (lhs: Vector4<Scalar>, rhs: Vector4<Scalar>)
    -> Vector4<Scalar> {
        return .init(lhs.storage / rhs.storage)
    }
    static func / (lhs: Vector4<Scalar>, rhs: Scalar)
    -> Vector4<Scalar> {
        return .init(lhs.storage / rhs)
    }
    static func / (lhs: Scalar, rhs: Vector4<Scalar>)
    -> Vector4<Scalar> {
        return .init(lhs / rhs.storage)
    }

    static func /= (lhs: inout Vector4<Scalar>, rhs: Vector4<Scalar>) {
        lhs.storage /= rhs.storage
    }
    static func /= (lhs: inout Vector4<Scalar>, rhs: Scalar) {
        lhs.storage /= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 204)
    static func % (lhs: Vector4<Scalar>, rhs: Vector4<Scalar>)
    -> Vector4<Scalar> {
        return .init(lhs.storage % rhs.storage)
    }
    static func % (lhs: Vector4<Scalar>, rhs: Scalar)
    -> Vector4<Scalar> {
        return .init(lhs.storage % rhs)
    }
    static func % (lhs: Scalar, rhs: Vector4<Scalar>)
    -> Vector4<Scalar> {
        return .init(lhs % rhs.storage)
    }

    static func %= (lhs: inout Vector4<Scalar>, rhs: Vector4<Scalar>) {
        lhs.storage %= rhs.storage
    }
    static func %= (lhs: inout Vector4<Scalar>, rhs: Scalar) {
        lhs.storage %= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 234)

    func roundedUp(exponent: Int) -> Vector4<Scalar> {
        let mask: Scalar                 = .max &<< exponent
        let truncated: SIMD4<Scalar>  = self.storage & mask
        let carry: SIMD4<Scalar> =
        SIMD4<Scalar>.zero.replacing(with: 1 &<< exponent, where: self.storage & ~mask .!= 0)
        return .init(truncated &+ carry)
    }

    var wrappingSum: Scalar {
        return self.x &+ self.y &+ self.z &+ self.w
    }
    var wrappingVolume: Scalar {
        return self.x &* self.y &* self.z &* self.w
    }

    static func &<> (lhs: Vector4<Scalar>, rhs: Vector4<Scalar>) -> Scalar {
        return (lhs &* rhs).wrappingSum
    }
}

extension Vector4 where Scalar: ExpressibleByIntegerLiteral {
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 262)
    static var i: Self {
        .init(1, 0, 0, 0)
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 262)
    static var j: Self {
        .init(0, 1, 0, 0)
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 262)
    static var k: Self {
        .init(0, 0, 1, 0)
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 262)
    static var h: Self {
        .init(0, 0, 0, 1)
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 268)
}

extension Vector4 where Scalar: FloatingPoint {
    static var zero: Vector4<Scalar> {
        return .init(.zero)
    }

    prefix static func - (operand: Vector4<Scalar>) -> Vector4<Scalar> {
        return .init(-operand.storage)
    }

    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 285)
    static func + (lhs: Vector4<Scalar>, rhs: Vector4<Scalar>)
    -> Vector4<Scalar> {
        return .init(lhs.storage + rhs.storage)
    }
    static func + (lhs: Vector4<Scalar>, rhs: Scalar)
    -> Vector4<Scalar> {
        return .init(lhs.storage + rhs)
    }
    static func + (lhs: Scalar, rhs: Vector4<Scalar>)
    -> Vector4<Scalar> {
        return .init(lhs + rhs.storage)
    }

    static func += (lhs: inout Vector4<Scalar>, rhs: Vector4<Scalar>) {
        lhs.storage += rhs.storage
    }
    static func += (lhs: inout Vector4<Scalar>, rhs: Scalar) {
        lhs.storage += rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 285)
    static func - (lhs: Vector4<Scalar>, rhs: Vector4<Scalar>)
    -> Vector4<Scalar> {
        return .init(lhs.storage - rhs.storage)
    }
    static func - (lhs: Vector4<Scalar>, rhs: Scalar)
    -> Vector4<Scalar> {
        return .init(lhs.storage - rhs)
    }
    static func - (lhs: Scalar, rhs: Vector4<Scalar>)
    -> Vector4<Scalar> {
        return .init(lhs - rhs.storage)
    }

    static func -= (lhs: inout Vector4<Scalar>, rhs: Vector4<Scalar>) {
        lhs.storage -= rhs.storage
    }
    static func -= (lhs: inout Vector4<Scalar>, rhs: Scalar) {
        lhs.storage -= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 285)
    static func * (lhs: Vector4<Scalar>, rhs: Vector4<Scalar>)
    -> Vector4<Scalar> {
        return .init(lhs.storage * rhs.storage)
    }
    static func * (lhs: Vector4<Scalar>, rhs: Scalar)
    -> Vector4<Scalar> {
        return .init(lhs.storage * rhs)
    }
    static func * (lhs: Scalar, rhs: Vector4<Scalar>)
    -> Vector4<Scalar> {
        return .init(lhs * rhs.storage)
    }

    static func *= (lhs: inout Vector4<Scalar>, rhs: Vector4<Scalar>) {
        lhs.storage *= rhs.storage
    }
    static func *= (lhs: inout Vector4<Scalar>, rhs: Scalar) {
        lhs.storage *= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 285)
    static func / (lhs: Vector4<Scalar>, rhs: Vector4<Scalar>)
    -> Vector4<Scalar> {
        return .init(lhs.storage / rhs.storage)
    }
    static func / (lhs: Vector4<Scalar>, rhs: Scalar)
    -> Vector4<Scalar> {
        return .init(lhs.storage / rhs)
    }
    static func / (lhs: Scalar, rhs: Vector4<Scalar>)
    -> Vector4<Scalar> {
        return .init(lhs / rhs.storage)
    }

    static func /= (lhs: inout Vector4<Scalar>, rhs: Vector4<Scalar>) {
        lhs.storage /= rhs.storage
    }
    static func /= (lhs: inout Vector4<Scalar>, rhs: Scalar) {
        lhs.storage /= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 315)

    func addingProduct(_ lhs: Vector4<Scalar>, _ rhs: Vector4<Scalar>) -> Vector4<Scalar> {
        return .init(self.storage.addingProduct(lhs.storage, rhs.storage))
    }
    func addingProduct(_ lhs: Scalar, _ rhs: Vector4<Scalar>) -> Vector4<Scalar> {
        return .init(self.storage.addingProduct(lhs, rhs.storage))
    }
    func addingProduct(_ lhs: Vector4<Scalar>, _ rhs: Scalar) -> Vector4<Scalar> {
        return .init(self.storage.addingProduct(lhs.storage, rhs))
    }
    mutating func addProduct(_ lhs: Vector4<Scalar>, _ rhs: Vector4<Scalar>) {
        self.storage.addProduct(lhs.storage, rhs.storage)
    }
    mutating func addProduct(_ lhs: Scalar, _ rhs: Vector4<Scalar>) {
        self.storage.addProduct(lhs, rhs.storage)
    }
    mutating func addProduct(_ lhs: Vector4<Scalar>, _ rhs: Scalar) {
        self.storage.addProduct(lhs.storage, rhs)
    }

    func squareRoot() -> Vector4<Scalar> {
        return .init(self.storage.squareRoot())
    }

    func rounded(_ rule: FloatingPointRoundingRule) -> Vector4<Scalar> {
        return .init(self.storage.rounded(rule))
    }
    mutating func round(_ rule: FloatingPointRoundingRule) {
        self.storage.round(rule)
    }

    static func interpolate(_ a: Vector4<Scalar>, _ b: Vector4<Scalar>, by t: Scalar)
    -> Vector4<Scalar> {
        return a.addingProduct(a, -t).addingProduct(b, t)
    }


    var sum: Scalar {
        return self.x + self.y + self.z + self.w
    }
    var volume: Scalar {
        return self.x * self.y * self.z * self.w
    }

    static func <> (lhs: Vector4<Scalar>, rhs: Vector4<Scalar>) -> Scalar {
        return (lhs * rhs).sum
    }

    var length: Scalar {
        return (self <> self).squareRoot()
    }

    mutating func normalize() {
        self /= self.length
    }
    func normalized() -> Vector4<Scalar> {
        return self / self.length
    }

    static func <  (v: Vector4<Scalar>, r: Scalar) -> Bool {
        return v <> v <  r
    }
    static func <= (v: Vector4<Scalar>, r: Scalar) -> Bool {
        return v <> v <= r
    }
    static func ~~ (v: Vector4<Scalar>, r: Scalar) -> Bool {
        return v <> v == r
    }
    static func !~ (v: Vector4<Scalar>, r: Scalar) -> Bool {
        return v <> v != r
    }
    static func >= (v: Vector4<Scalar>, r: Scalar) -> Bool {
        return v <> v >= r
    }
    static func >  (v: Vector4<Scalar>, r: Scalar) -> Bool {
        return v <> v >  r
    }
}

func wrappingAbs<Scalar>(
    _ v: Vector4<Scalar>
) -> Vector4<Scalar> where Scalar: FixedWidthInteger {
    return .init(v.storage.replacing(with: 0 &- v.storage, where: v.storage .< 0))
}
func         abs<Scalar>(_ v: Vector4<Scalar>) -> Vector4<Scalar> where Scalar: FloatingPoint {
    return .init(v.storage.replacing(with: -v.storage, where: v.storage .< 0))
}

// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 432)

extension Vector2 where Scalar: FixedWidthInteger {
    static func &>< (lhs: Vector2<Scalar>, rhs: Vector2<Scalar>) -> Scalar {
        return lhs.x &* rhs.y &- rhs.x &* lhs.y
    }
}
extension Vector2 where Scalar: FloatingPoint {
    static func >< (lhs: Vector2<Scalar>, rhs: Vector2<Scalar>) -> Scalar {
        return lhs.x * rhs.y - rhs.x * lhs.y
    }
}
extension Vector3 where Scalar: FixedWidthInteger {
    static func &>< (lhs: Vector3<Scalar>, rhs: Vector3<Scalar>) -> Vector3<Scalar> {
        return  .init(lhs.y, lhs.z, lhs.x) &* .init(rhs.z, rhs.x, rhs.y) &-
        .init(rhs.y, rhs.z, rhs.x) &* .init(lhs.z, lhs.x, lhs.y)
    }
}
extension Vector3 where Scalar: FloatingPoint {
    static func >< (lhs: Vector3<Scalar>, rhs: Vector3<Scalar>) -> Vector3<Scalar> {
        return  .init(lhs.y, lhs.z, lhs.x) * .init(rhs.z, rhs.x, rhs.y) -
        .init(rhs.y, rhs.z, rhs.x) * .init(lhs.z, lhs.x, lhs.y)
    }
}

extension Spherical2 where Scalar: ElementaryFunctions {
    init(cartesian: Vector3<Scalar>) {
        let colatitude: Scalar = Scalar.acos(cartesian.z / cartesian.length)
        let longitude: Scalar  = Scalar.argument(y: cartesian.y, x: cartesian.x)
        self.init(colatitude, longitude)
    }

    init(normalized cartesian: Vector3<Scalar>) {
        let colatitude: Scalar = Scalar.acos(cartesian.z)
        let longitude: Scalar  = Scalar.argument(y: cartesian.y, x: cartesian.x)
        self.init(colatitude, longitude)
    }
}
extension Vector3 where Scalar: FloatingPoint & ElementaryFunctions {
    init(spherical: Spherical2<Scalar>) {
        let ll: Vector2<Scalar>  = .init(spherical.storage)
        let sin: Vector2<Scalar> = .init(.sin(ll.storage)),
        cos: Vector2<Scalar> = .init(.cos(ll.storage))
        self = .extend(.init(cos.y, sin.y) * sin.x, cos.x)
    }
}

struct Spherical2<Scalar> where Scalar: SIMDScalar & FloatingPoint & ElementaryFunctions {
    var storage: SIMD2<Scalar>

    var colatitude: Scalar {
        get {
            return self.storage.x
        }
        set(x) {
            self.storage.x = x
        }
    }
    var longitude: Scalar {
        get {
            return self.storage.y
        }
        set(y) {
            self.storage.y = y
        }
    }

    init(_ colatitude: Scalar, _ longitude: Scalar) {
        self.init(.init(colatitude, longitude))
    }

    init(_ storage: SIMD2<Scalar>) {
        self.storage = storage
    }

    func map<Result>(_ transform: (Scalar) throws -> Result) rethrows -> Spherical2<Result>
        where Result: SIMDScalar {
        return .init(try transform(self.colatitude), try transform(self.longitude))
    }


    static var zero: Spherical2<Scalar> {
        return .init(.zero)
    }

    prefix static func - (operand: Spherical2<Scalar>) -> Spherical2<Scalar> {
        return .init(-operand.storage)
    }

    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 552)
    static func + (lhs: Spherical2<Scalar>, rhs: Spherical2<Scalar>)
    -> Spherical2<Scalar> {
        return .init(lhs.storage + rhs.storage)
    }
    static func + (lhs: Spherical2<Scalar>, rhs: Scalar)
    -> Spherical2<Scalar> {
        return .init(lhs.storage + rhs)
    }
    static func + (lhs: Scalar, rhs: Spherical2<Scalar>)
    -> Spherical2<Scalar> {
        return .init(lhs + rhs.storage)
    }

    static func += (lhs: inout Spherical2<Scalar>, rhs: Spherical2<Scalar>) {
        lhs.storage += rhs.storage
    }
    static func += (lhs: inout Spherical2<Scalar>, rhs: Scalar) {
        lhs.storage += rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 552)
    static func - (lhs: Spherical2<Scalar>, rhs: Spherical2<Scalar>)
    -> Spherical2<Scalar> {
        return .init(lhs.storage - rhs.storage)
    }
    static func - (lhs: Spherical2<Scalar>, rhs: Scalar)
    -> Spherical2<Scalar> {
        return .init(lhs.storage - rhs)
    }
    static func - (lhs: Scalar, rhs: Spherical2<Scalar>)
    -> Spherical2<Scalar> {
        return .init(lhs - rhs.storage)
    }

    static func -= (lhs: inout Spherical2<Scalar>, rhs: Spherical2<Scalar>) {
        lhs.storage -= rhs.storage
    }
    static func -= (lhs: inout Spherical2<Scalar>, rhs: Scalar) {
        lhs.storage -= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 552)
    static func * (lhs: Spherical2<Scalar>, rhs: Spherical2<Scalar>)
    -> Spherical2<Scalar> {
        return .init(lhs.storage * rhs.storage)
    }
    static func * (lhs: Spherical2<Scalar>, rhs: Scalar)
    -> Spherical2<Scalar> {
        return .init(lhs.storage * rhs)
    }
    static func * (lhs: Scalar, rhs: Spherical2<Scalar>)
    -> Spherical2<Scalar> {
        return .init(lhs * rhs.storage)
    }

    static func *= (lhs: inout Spherical2<Scalar>, rhs: Spherical2<Scalar>) {
        lhs.storage *= rhs.storage
    }
    static func *= (lhs: inout Spherical2<Scalar>, rhs: Scalar) {
        lhs.storage *= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 552)
    static func / (lhs: Spherical2<Scalar>, rhs: Spherical2<Scalar>)
    -> Spherical2<Scalar> {
        return .init(lhs.storage / rhs.storage)
    }
    static func / (lhs: Spherical2<Scalar>, rhs: Scalar)
    -> Spherical2<Scalar> {
        return .init(lhs.storage / rhs)
    }
    static func / (lhs: Scalar, rhs: Spherical2<Scalar>)
    -> Spherical2<Scalar> {
        return .init(lhs / rhs.storage)
    }

    static func /= (lhs: inout Spherical2<Scalar>, rhs: Spherical2<Scalar>) {
        lhs.storage /= rhs.storage
    }
    static func /= (lhs: inout Spherical2<Scalar>, rhs: Scalar) {
        lhs.storage /= rhs
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 582)

    func addingProduct(
        _ lhs: Spherical2<Scalar>,
        _ rhs: Spherical2<Scalar>
    ) -> Spherical2<Scalar> {
        return .init(self.storage.addingProduct(lhs.storage, rhs.storage))
    }
    func addingProduct(_ lhs: Scalar, _ rhs: Spherical2<Scalar>) -> Spherical2<Scalar> {
        return .init(self.storage.addingProduct(lhs, rhs.storage))
    }
    func addingProduct(_ lhs: Spherical2<Scalar>, _ rhs: Scalar) -> Spherical2<Scalar> {
        return .init(self.storage.addingProduct(lhs.storage, rhs))
    }
    mutating func addProduct(_ lhs: Spherical2<Scalar>, _ rhs: Spherical2<Scalar>) {
        self.storage.addProduct(lhs.storage, rhs.storage)
    }
    mutating func addProduct(_ lhs: Scalar, _ rhs: Spherical2<Scalar>) {
        self.storage.addProduct(lhs, rhs.storage)
    }
    mutating func addProduct(_ lhs: Spherical2<Scalar>, _ rhs: Scalar) {
        self.storage.addProduct(lhs.storage, rhs)
    }

    func squareRoot() -> Spherical2<Scalar> {
        return .init(self.storage.squareRoot())
    }

    func rounded(_ rule: FloatingPointRoundingRule) -> Spherical2<Scalar> {
        return .init(self.storage.rounded(rule))
    }
    mutating func round(_ rule: FloatingPointRoundingRule) {
        self.storage.round(rule)
    }
}

// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 628)
struct Matrix2<T>: Equatable where T: SIMDScalar {
    private var columns: (Vector2<T>, Vector2<T>)

    var transposed: Matrix2<T> {
        return .init(
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 637)
            .init(self.columns.0.x, self.columns.1.x),
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 637)
            .init(self.columns.0.y, self.columns.1.y)
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 639)
        )
    }

    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 648)

    @inline(__always) subscript(column: Int) -> Vector2<T> {
        get {
            switch column {
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 657)
            case 0:
                return self.columns.0
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 657)
            case 1:
                return self.columns.1
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 660)
            default:
                fatalError("Matrix column index out of range")
            }
        }
        set(value) {
            switch column {
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 669)
            case 0:
                self.columns.0 = value
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 669)
            case 1:
                self.columns.1 = value
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 672)
            default:
                fatalError("Matrix column index out of range")
            }
        }
    }

    init(_ v0: Vector2<T>, _ v1: Vector2<T>) {
        self.columns = (v0, v1)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.columns.0 == rhs.columns.0 && lhs.columns.1 == rhs.columns.1
    }
}

extension Matrix2 where T: Numeric {
    static var identity: Matrix2<T> {
        return .init(
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 697)
            .init(1, 0),
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 697)
            .init(0, 1)
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 699)
        )
    }
}
extension Matrix2 where T: FixedWidthInteger {
    static func &>< (A: Matrix2<T>, v: Vector2<T>) -> Vector2<T> {
        return A.columns.0 &* v.x &+ A.columns.1 &* v.y
    }

    static func &>< (A: Matrix2<T>, B: Matrix2<T>) -> Matrix2<T> {
        return .init(A &>< B.columns.0, A &>< B.columns.1)
    }
}
extension Matrix2 where T: FloatingPoint {
    static func >< (A: Matrix2<T>, v: Vector2<T>) -> Vector2<T> {
        return (A.columns.0 * v.x).addingProduct(A.columns.1, v.y)
    }

    static func >< (A: Matrix2<T>, B: Matrix2<T>) -> Matrix2<T> {
        return .init(A >< B.columns.0, A >< B.columns.1)
    }
}
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 628)
struct Matrix3<T>: Equatable where T: SIMDScalar {
    private var columns: (Vector3<T>, Vector3<T>, Vector3<T>)

    var transposed: Matrix3<T> {
        return .init(
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 637)
            .init(self.columns.0.x, self.columns.1.x, self.columns.2.x),
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 637)
            .init(self.columns.0.y, self.columns.1.y, self.columns.2.y),
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 637)
            .init(self.columns.0.z, self.columns.1.z, self.columns.2.z)
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 639)
        )
    }

    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 643)
    var matrix2: Matrix2<T> {
        return .init(self.columns.0.xy, self.columns.1.xy)
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 648)

    @inline(__always) subscript(column: Int) -> Vector3<T> {
        get {
            switch column {
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 657)
            case 0:
                return self.columns.0
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 657)
            case 1:
                return self.columns.1
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 657)
            case 2:
                return self.columns.2
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 660)
            default:
                fatalError("Matrix column index out of range")
            }
        }
        set(value) {
            switch column {
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 669)
            case 0:
                self.columns.0 = value
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 669)
            case 1:
                self.columns.1 = value
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 669)
            case 2:
                self.columns.2 = value
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 672)
            default:
                fatalError("Matrix column index out of range")
            }
        }
    }

    init(_ v0: Vector3<T>, _ v1: Vector3<T>, _ v2: Vector3<T>) {
        self.columns = (v0, v1, v2)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.columns.0 == rhs.columns.0 && lhs.columns.1 == rhs.columns.1 && lhs.columns.2 == rhs.columns.2
    }
}

extension Matrix3 where T: Numeric {
    static var identity: Matrix3<T> {
        return .init(
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 697)
            .init(1, 0, 0),
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 697)
            .init(0, 1, 0),
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 697)
            .init(0, 0, 1)
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 699)
        )
    }
}
extension Matrix3 where T: FixedWidthInteger {
    static func &>< (A: Matrix3<T>, v: Vector3<T>) -> Vector3<T> {
        return A.columns.0 &* v.x &+ A.columns.1 &* v.y &+ A.columns.2 &* v.z
    }

    static func &>< (A: Matrix3<T>, B: Matrix3<T>) -> Matrix3<T> {
        return .init(A &>< B.columns.0, A &>< B.columns.1, A &>< B.columns.2)
    }
}
extension Matrix3 where T: FloatingPoint {
    static func >< (A: Matrix3<T>, v: Vector3<T>) -> Vector3<T> {
        return (A.columns.0 * v.x).addingProduct(A.columns.1, v.y).addingProduct(
            A.columns.2,
            v.z
        )
    }

    static func >< (A: Matrix3<T>, B: Matrix3<T>) -> Matrix3<T> {
        return .init(A >< B.columns.0, A >< B.columns.1, A >< B.columns.2)
    }
}
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 628)
struct Matrix4<T>: Equatable where T: SIMDScalar {
    private var columns: (Vector4<T>, Vector4<T>, Vector4<T>, Vector4<T>)

    var transposed: Matrix4<T> {
        return .init(
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 637)
            .init(self.columns.0.x, self.columns.1.x, self.columns.2.x, self.columns.3.x),
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 637)
            .init(self.columns.0.y, self.columns.1.y, self.columns.2.y, self.columns.3.y),
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 637)
            .init(self.columns.0.z, self.columns.1.z, self.columns.2.z, self.columns.3.z),
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 637)
            .init(self.columns.0.w, self.columns.1.w, self.columns.2.w, self.columns.3.w)
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 639)
        )
    }

    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 643)
    var matrix3: Matrix3<T> {
        return .init(self.columns.0.xyz, self.columns.1.xyz, self.columns.2.xyz)
    }
    // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 648)

    @inline(__always) subscript(column: Int) -> Vector4<T> {
        get {
            switch column {
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 657)
            case 0:
                return self.columns.0
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 657)
            case 1:
                return self.columns.1
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 657)
            case 2:
                return self.columns.2
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 657)
            case 3:
                return self.columns.3
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 660)
            default:
                fatalError("Matrix column index out of range")
            }
        }
        set(value) {
            switch column {
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 669)
            case 0:
                self.columns.0 = value
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 669)
            case 1:
                self.columns.1 = value
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 669)
            case 2:
                self.columns.2 = value
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 669)
            case 3:
                self.columns.3 = value
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 672)
            default:
                fatalError("Matrix column index out of range")
            }
        }
    }

    init(_ v0: Vector4<T>, _ v1: Vector4<T>, _ v2: Vector4<T>, _ v3: Vector4<T>) {
        self.columns = (v0, v1, v2, v3)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.columns.0 == rhs.columns.0 && lhs.columns.1 == rhs.columns.1 && lhs.columns.2 == rhs.columns.2 && lhs.columns.3 == rhs.columns.3
    }
}

extension Matrix4 where T: Numeric {
    static var identity: Matrix4<T> {
        return .init(
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 697)
            .init(1, 0, 0, 0),
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 697)
            .init(0, 1, 0, 0),
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 697)
            .init(0, 0, 1, 0),
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 697)
            .init(0, 0, 0, 1)
            // ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 699)
        )
    }
}
extension Matrix4 where T: FixedWidthInteger {
    static func &>< (A: Matrix4<T>, v: Vector4<T>) -> Vector4<T> {
        return A.columns.0 &* v.x &+ A.columns.1 &* v.y &+ A.columns.2 &* v.z &+ A.columns.3 &* v.w
    }

    static func &>< (A: Matrix4<T>, B: Matrix4<T>) -> Matrix4<T> {
        return .init(A &>< B.columns.0, A &>< B.columns.1, A &>< B.columns.2, A &>< B.columns.3)
    }
}
extension Matrix4 where T: FloatingPoint {
    static func >< (A: Matrix4<T>, v: Vector4<T>) -> Vector4<T> {
        return (A.columns.0 * v.x).addingProduct(A.columns.1, v.y).addingProduct(
            A.columns.2,
            v.z
        ).addingProduct(
            A.columns.3,
            v.w
        )
    }

    static func >< (A: Matrix4<T>, B: Matrix4<T>) -> Matrix4<T> {
        return .init(A >< B.columns.0, A >< B.columns.1, A >< B.columns.2, A >< B.columns.3)
    }
}
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/vector.swift.gyb", line: 731)

extension Matrix2 where T: FloatingPoint {
    func inversed() -> Self {
        let a: T = self.columns.0.x,
        b: T = self.columns.1.x,
        c: T = self.columns.0.y,
        d: T = self.columns.1.y

        let determinant: T = 1 / (a * d - b * c)
        return .init(determinant * .init(d, -c), determinant * .init(-b, a))
    }
}


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
