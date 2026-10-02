#if canImport(Darwin)
import Darwin
enum Platform {
    @inline(__always) static func sqrt(_ x: Float) -> Float { Darwin.sqrt(x) }
    @inline(__always) static func log(_ x: Float) -> Float { Darwin.log(x) }
    @inline(__always) static func exp(_ x: Float) -> Float { Darwin.exp(x) }
    @inline(__always) static func sin(_ x: Float) -> Float { Darwin.sin(x) }
    @inline(__always) static func cos(_ x: Float) -> Float { Darwin.cos(x) }
    @inline(__always) static func tan(_ x: Float) -> Float { Darwin.tan(x) }
    @inline(__always) static func asin(_ x: Float) -> Float { Darwin.asin(x) }
    @inline(__always) static func acos(_ x: Float) -> Float { Darwin.acos(x) }
    @inline(__always) static func atan(_ x: Float) -> Float { Darwin.atan(x) }
    @inline(__always) static func pow(_ b: Float, _ e: Float) -> Float { Darwin.pow(b, e) }
    @inline(__always) static func atan2(_ y: Float, _ x: Float) -> Float { Darwin.atan2(y, x) }

    @inline(__always) static func sqrt(_ x: Double) -> Double { Darwin.sqrt(x) }
    @inline(__always) static func log(_ x: Double) -> Double { Darwin.log(x) }
    @inline(__always) static func exp(_ x: Double) -> Double { Darwin.exp(x) }
    @inline(__always) static func sin(_ x: Double) -> Double { Darwin.sin(x) }
    @inline(__always) static func cos(_ x: Double) -> Double { Darwin.cos(x) }
    @inline(__always) static func tan(_ x: Double) -> Double { Darwin.tan(x) }
    @inline(__always) static func asin(_ x: Double) -> Double { Darwin.asin(x) }
    @inline(__always) static func acos(_ x: Double) -> Double { Darwin.acos(x) }
    @inline(__always) static func atan(_ x: Double) -> Double { Darwin.atan(x) }
    @inline(__always) static func pow(_ b: Double, _ e: Double) -> Double { Darwin.pow(b, e) }
    @inline(__always) static func atan2(_ y: Double, _ x: Double) -> Double {
        Darwin.atan2(y, x)
    }
}
typealias Glibc = Platform
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
typealias Glibc = Musl
#endif

protocol ElementaryFunctions {
    static func sqrt(_ x: Self) -> Self
    static func log(_ x: Self) -> Self
    static func exp(_ x: Self) -> Self
    static func sin(_ x: Self) -> Self
    static func cos(_ x: Self) -> Self
    static func tan(_ x: Self) -> Self
    static func asin(_ x: Self) -> Self
    static func acos(_ x: Self) -> Self
    static func atan(_ x: Self) -> Self

    static func power(_ base: Self, to exponent: Self) -> Self
    static func argument(y: Self, x: Self) -> Self
}

extension Float: ElementaryFunctions {
    static func sqrt(_ x: Self) -> Self {
        return Glibc.sqrt(x)
    }
    static func log(_ x: Self) -> Self {
        return Glibc.log(x)
    }
    static func exp(_ x: Self) -> Self {
        return Glibc.exp(x)
    }
    static func sin(_ x: Self) -> Self {
        return Glibc.sin(x)
    }
    static func cos(_ x: Self) -> Self {
        return Glibc.cos(x)
    }
    static func tan(_ x: Self) -> Self {
        return Glibc.tan(x)
    }
    static func asin(_ x: Self) -> Self {
        return Glibc.asin(x)
    }
    static func acos(_ x: Self) -> Self {
        return Glibc.acos(x)
    }
    static func atan(_ x: Self) -> Self {
        return Glibc.atan(x)
    }

    static func power(_ base: Self, to exponent: Self) -> Self {
        return Glibc.pow(base, exponent)
    }

    static func argument(y: Self, x: Self) -> Self {
        return Glibc.atan2(y, x)
    }
}
extension Double: ElementaryFunctions {
    static func sqrt(_ x: Self) -> Self {
        return Glibc.sqrt(x)
    }
    static func log(_ x: Self) -> Self {
        return Glibc.log(x)
    }
    static func exp(_ x: Self) -> Self {
        return Glibc.exp(x)
    }
    static func sin(_ x: Self) -> Self {
        return Glibc.sin(x)
    }
    static func cos(_ x: Self) -> Self {
        return Glibc.cos(x)
    }
    static func tan(_ x: Self) -> Self {
        return Glibc.tan(x)
    }
    static func asin(_ x: Self) -> Self {
        return Glibc.asin(x)
    }
    static func acos(_ x: Self) -> Self {
        return Glibc.acos(x)
    }
    static func atan(_ x: Self) -> Self {
        return Glibc.atan(x)
    }

    static func power(_ base: Self, to exponent: Self) -> Self {
        return Glibc.pow(base, exponent)
    }

    static func argument(y: Self, x: Self) -> Self {
        return Glibc.atan2(y, x)
    }
}

extension SIMD2 where Scalar: ElementaryFunctions {
    static func sqrt(_ x: Self) -> Self {
        return .init(
            Scalar.sqrt(x.x), Scalar.sqrt(x.y)
        )
    }
    static func log(_ x: Self) -> Self {
        return .init(
            Scalar.log(x.x), Scalar.log(x.y)
        )
    }
    static func exp(_ x: Self) -> Self {
        return .init(
            Scalar.exp(x.x), Scalar.exp(x.y)
        )
    }
    static func sin(_ x: Self) -> Self {
        return .init(
            Scalar.sin(x.x), Scalar.sin(x.y)
        )
    }
    static func cos(_ x: Self) -> Self {
        return .init(
            Scalar.cos(x.x), Scalar.cos(x.y)
        )
    }
    static func tan(_ x: Self) -> Self {
        return .init(
            Scalar.tan(x.x), Scalar.tan(x.y)
        )
    }
    static func asin(_ x: Self) -> Self {
        return .init(
            Scalar.asin(x.x), Scalar.asin(x.y)
        )
    }
    static func acos(_ x: Self) -> Self {
        return .init(
            Scalar.acos(x.x), Scalar.acos(x.y)
        )
    }
    static func atan(_ x: Self) -> Self {
        return .init(
            Scalar.atan(x.x), Scalar.atan(x.y)
        )
    }
}
extension SIMD3 where Scalar: ElementaryFunctions {
    static func sqrt(_ x: Self) -> Self {
        return .init(
            Scalar.sqrt(x.x), Scalar.sqrt(x.y), Scalar.sqrt(x.z)
        )
    }
    static func log(_ x: Self) -> Self {
        return .init(
            Scalar.log(x.x), Scalar.log(x.y), Scalar.log(x.z)
        )
    }
    static func exp(_ x: Self) -> Self {
        return .init(
            Scalar.exp(x.x), Scalar.exp(x.y), Scalar.exp(x.z)
        )
    }
    static func sin(_ x: Self) -> Self {
        return .init(
            Scalar.sin(x.x), Scalar.sin(x.y), Scalar.sin(x.z)
        )
    }
    static func cos(_ x: Self) -> Self {
        return .init(
            Scalar.cos(x.x), Scalar.cos(x.y), Scalar.cos(x.z)
        )
    }
    static func tan(_ x: Self) -> Self {
        return .init(
            Scalar.tan(x.x), Scalar.tan(x.y), Scalar.tan(x.z)
        )
    }
    static func asin(_ x: Self) -> Self {
        return .init(
            Scalar.asin(x.x), Scalar.asin(x.y), Scalar.asin(x.z)
        )
    }
    static func acos(_ x: Self) -> Self {
        return .init(
            Scalar.acos(x.x), Scalar.acos(x.y), Scalar.acos(x.z)
        )
    }
    static func atan(_ x: Self) -> Self {
        return .init(
            Scalar.atan(x.x), Scalar.atan(x.y), Scalar.atan(x.z)
        )
    }
}
extension SIMD4 where Scalar: ElementaryFunctions {
    static func sqrt(_ x: Self) -> Self {
        return .init(
            Scalar.sqrt(x.x), Scalar.sqrt(x.y), Scalar.sqrt(x.z), Scalar.sqrt(x.w)
        )
    }
    static func log(_ x: Self) -> Self {
        return .init(
            Scalar.log(x.x), Scalar.log(x.y), Scalar.log(x.z), Scalar.log(x.w)
        )
    }
    static func exp(_ x: Self) -> Self {
        return .init(
            Scalar.exp(x.x), Scalar.exp(x.y), Scalar.exp(x.z), Scalar.exp(x.w)
        )
    }
    static func sin(_ x: Self) -> Self {
        return .init(
            Scalar.sin(x.x), Scalar.sin(x.y), Scalar.sin(x.z), Scalar.sin(x.w)
        )
    }
    static func cos(_ x: Self) -> Self {
        return .init(
            Scalar.cos(x.x), Scalar.cos(x.y), Scalar.cos(x.z), Scalar.cos(x.w)
        )
    }
    static func tan(_ x: Self) -> Self {
        return .init(
            Scalar.tan(x.x), Scalar.tan(x.y), Scalar.tan(x.z), Scalar.tan(x.w)
        )
    }
    static func asin(_ x: Self) -> Self {
        return .init(
            Scalar.asin(x.x), Scalar.asin(x.y), Scalar.asin(x.z), Scalar.asin(x.w)
        )
    }
    static func acos(_ x: Self) -> Self {
        return .init(
            Scalar.acos(x.x), Scalar.acos(x.y), Scalar.acos(x.z), Scalar.acos(x.w)
        )
    }
    static func atan(_ x: Self) -> Self {
        return .init(
            Scalar.atan(x.x), Scalar.atan(x.y), Scalar.atan(x.z), Scalar.atan(x.w)
        )
    }
}
