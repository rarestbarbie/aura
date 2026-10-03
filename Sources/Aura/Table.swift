protocol Table {
    typealias D2            = _TableD2
    typealias D3            = _TableD3
    typealias Transmittance = _TableTransmittance
    typealias Scattering    = _TableScattering
    typealias Irradiance    = _TableIrradiance

    associatedtype F: SwiftFloatingPoint
    associatedtype Element
    var atmosphere: Atmosphere<F> {
        get
    }
    var buffer: [Element] {
        get
        set
    }
}
protocol _TableD2: Table {
    var size: Vector2<Int> {
        get
    }
}
extension Table.D2 {
    subscript(y y: Int, x x: Int) -> Element {
        get {
            self.buffer[y * self.size.x + x]
        }
        set(value) {
            self.buffer[y * self.size.x + x] = value
        }
    }

    static func mapIndices<R>(
        size: Vector2<Int>,
        transform: (Vector2<Int>) throws -> R
    ) rethrows -> [R] {
        return try .init(unsafeUninitializedCapacity: size.wrappingVolume) {
            for j: Int in 0 ..< size.y {
                for i: Int in 0 ..< size.x {
                    $0[j * size.x + i] = try transform(.init(i, j))
                }
            }
            $1 = size.wrappingVolume
        }
    }
}
protocol _TableD3: Table {
    var size: Vector3<Int> {
        get
    }
}
extension Table.D3 {
    subscript(z z: Int, y y: Int, x x: Int) -> Element {
        get {
            self.buffer[(z * self.size.y + y) * self.size.x + x]
        }
        set(value) {
            self.buffer[(z * self.size.y + y) * self.size.x + x] = value
        }
    }

    static func mapIndices<R>(
        size: Vector3<Int>,
        transform: (Vector3<Int>) throws -> R
    ) rethrows -> [R] {
        return try .init(unsafeUninitializedCapacity: size.wrappingVolume) {
            for k: Int in 0 ..< size.z {
                for j: Int in 0 ..< size.y {
                    for i: Int in 0 ..< size.x {
                        $0[(k * size.y + j) * size.x + i] = try transform(.init(i, j, k))
                    }
                }
            }
            $1 = size.wrappingVolume
        }
    }
}

// bilinear interpolation
extension Table.D2 where Element == Vector3<F> {
    subscript(t: Vector2<F>) -> Vector3<F> {
        // subtract 0.5 because output of `transmittanceTextureCoordinate(r:μ:)`
        // gives coordinates bounded by pixel centers. doing this makes it so
        // the minimum output of that function maps to [0] and the maximum maps
        // to [n - 1]
        let T: Vector2<F> = t * .cast(self.size) - 0.5
        let i: (Int, Int),
        j: (Int, Int)
        i.0 = max(0, min(.init(T.x), self.size.x - 1))
        i.1 =        min(i.0 + 1,    self.size.x - 1)
        j.0 = max(0, min(.init(T.y), self.size.y - 1))
        j.1 =        min(j.0 + 1,    self.size.y - 1)
        let (u, v): (F, F) = (T.x - T.x.rounded(.down), T.y - T.y.rounded(.down))
        let y: (Vector3<F>, Vector3<F>) = (
            self[y: j.0, x: i.0] * (1 - u) + self[y: j.0, x: i.1] * u,
            self[y: j.1, x: i.0] * (1 - u) + self[y: j.1, x: i.1] * u
        )
        return y.0 * (1 - v) + y.1 * v
    }
}
// trilinear interpolation
extension Table.D3 where Element == Vector3<F> {
    subscript(t: Vector3<F>) -> Vector3<F> {
        // subtract 0.5 because output of `transmittanceTextureCoordinate(r:μ:)`
        // gives coordinates bounded by pixel centers. doing this makes it so
        // the minimum output of that function maps to [0] and the maximum maps
        // to [n - 1]
        let T: Vector3<F> = t * .cast(self.size) - 0.5
        let i: (Int, Int),
        j: (Int, Int),
        k: (Int, Int)
        i.0 = max(0, min(.init(T.x), self.size.x - 1))
        i.1 =        min(i.0 + 1,    self.size.x - 1)
        j.0 = max(0, min(.init(T.y), self.size.y - 1))
        j.1 =        min(j.0 + 1,    self.size.y - 1)
        k.0 = max(0, min(.init(T.z), self.size.z - 1))
        k.1 =        min(k.0 + 1,    self.size.z - 1)
        let u: (F, F, F) = (
            T.x - T.x.rounded(.down),
            T.y - T.y.rounded(.down),
            T.z - T.z.rounded(.down)
        )
        let y: ((Vector3<F>, Vector3<F>), (Vector3<F>, Vector3<F>)) = (
            (
                self[z: k.0, y: j.0, x: i.0] * (1 - u.0) + self[z: k.0, y: j.0, x: i.1] * u.0,
                self[z: k.0, y: j.1, x: i.0] * (1 - u.0) + self[z: k.0, y: j.1, x: i.1] * u.0
            ),
            (
                self[z: k.1, y: j.0, x: i.0] * (1 - u.0) + self[z: k.1, y: j.0, x: i.1] * u.0,
                self[z: k.1, y: j.1, x: i.0] * (1 - u.0) + self[z: k.1, y: j.1, x: i.1] * u.0
            )
        )
        let z: (Vector3<F>, Vector3<F>) = (
            y.0.0 * (1 - u.1) + y.0.1 * u.1,
            y.1.0 * (1 - u.1) + y.1.1 * u.1
        )
        return z.0 * (1 - u.2) + z.1 * u.2
    }
}
