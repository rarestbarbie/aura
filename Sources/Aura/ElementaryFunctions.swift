#if canImport(Darwin)
import Darwin
typealias Glibc = Darwin
#elseif canImport(Glibc)
import Glibc
import func Glibc.atan2
import func Glibc.pow
import func Glibc.sqrt
import func Glibc.log
import func Glibc.exp
import func Glibc.sin
import func Glibc.cos
import func Glibc.tan
import func Glibc.asin
import func Glibc.acos
import func Glibc.atan
#elseif canImport(Musl)
import Musl
typealias Glibc = Musl
#endif

protocol ElementaryFunctions 
{
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 15)
    static 
    func sqrt(_ x:Self) -> Self 
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 15)
    static 
    func log(_ x:Self) -> Self 
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 15)
    static 
    func exp(_ x:Self) -> Self 
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 15)
    static 
    func sin(_ x:Self) -> Self 
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 15)
    static 
    func cos(_ x:Self) -> Self 
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 15)
    static 
    func tan(_ x:Self) -> Self 
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 15)
    static 
    func asin(_ x:Self) -> Self 
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 15)
    static 
    func acos(_ x:Self) -> Self 
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 15)
    static 
    func atan(_ x:Self) -> Self 
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 18)
    
    static 
    func power(_ base:Self, to exponent:Self) -> Self 
    static 
    func argument(y:Self, x:Self) -> Self 
}

// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 26)
extension Float:ElementaryFunctions
{
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 29)
    static 
    func sqrt(_ x:Self) -> Self 
    {
        return Glibc.sqrt(x)
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 29)
    static 
    func log(_ x:Self) -> Self 
    {
        return Glibc.log(x)
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 29)
    static 
    func exp(_ x:Self) -> Self 
    {
        return Glibc.exp(x)
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 29)
    static 
    func sin(_ x:Self) -> Self 
    {
        return Glibc.sin(x)
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 29)
    static 
    func cos(_ x:Self) -> Self 
    {
        return Glibc.cos(x)
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 29)
    static 
    func tan(_ x:Self) -> Self 
    {
        return Glibc.tan(x)
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 29)
    static 
    func asin(_ x:Self) -> Self 
    {
        return Glibc.asin(x)
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 29)
    static 
    func acos(_ x:Self) -> Self 
    {
        return Glibc.acos(x)
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 29)
    static 
    func atan(_ x:Self) -> Self 
    {
        return Glibc.atan(x)
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 35)
    
    static 
    func power(_ base:Self, to exponent:Self) -> Self 
    {
        return Glibc.pow(base, exponent)
    }
    
    static 
    func argument(y:Self, x:Self) -> Self 
    {
        return Glibc.atan2(y, x)
    }
}
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 26)
extension Double:ElementaryFunctions
{
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 29)
    static 
    func sqrt(_ x:Self) -> Self 
    {
        return Glibc.sqrt(x)
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 29)
    static 
    func log(_ x:Self) -> Self 
    {
        return Glibc.log(x)
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 29)
    static 
    func exp(_ x:Self) -> Self 
    {
        return Glibc.exp(x)
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 29)
    static 
    func sin(_ x:Self) -> Self 
    {
        return Glibc.sin(x)
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 29)
    static 
    func cos(_ x:Self) -> Self 
    {
        return Glibc.cos(x)
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 29)
    static 
    func tan(_ x:Self) -> Self 
    {
        return Glibc.tan(x)
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 29)
    static 
    func asin(_ x:Self) -> Self 
    {
        return Glibc.asin(x)
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 29)
    static 
    func acos(_ x:Self) -> Self 
    {
        return Glibc.acos(x)
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 29)
    static 
    func atan(_ x:Self) -> Self 
    {
        return Glibc.atan(x)
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 35)
    
    static 
    func power(_ base:Self, to exponent:Self) -> Self 
    {
        return Glibc.pow(base, exponent)
    }
    
    static 
    func argument(y:Self, x:Self) -> Self 
    {
        return Glibc.atan2(y, x)
    }
}
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 49)

// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 51)
extension SIMD2 where Scalar:ElementaryFunctions
{
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 54)
    static 
    func sqrt(_ x:Self) -> Self 
    {
        return .init(
            Scalar.sqrt(x.x), Scalar.sqrt(x.y)
            )
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 54)
    static 
    func log(_ x:Self) -> Self 
    {
        return .init(
            Scalar.log(x.x), Scalar.log(x.y)
            )
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 54)
    static 
    func exp(_ x:Self) -> Self 
    {
        return .init(
            Scalar.exp(x.x), Scalar.exp(x.y)
            )
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 54)
    static 
    func sin(_ x:Self) -> Self 
    {
        return .init(
            Scalar.sin(x.x), Scalar.sin(x.y)
            )
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 54)
    static 
    func cos(_ x:Self) -> Self 
    {
        return .init(
            Scalar.cos(x.x), Scalar.cos(x.y)
            )
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 54)
    static 
    func tan(_ x:Self) -> Self 
    {
        return .init(
            Scalar.tan(x.x), Scalar.tan(x.y)
            )
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 54)
    static 
    func asin(_ x:Self) -> Self 
    {
        return .init(
            Scalar.asin(x.x), Scalar.asin(x.y)
            )
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 54)
    static 
    func acos(_ x:Self) -> Self 
    {
        return .init(
            Scalar.acos(x.x), Scalar.acos(x.y)
            )
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 54)
    static 
    func atan(_ x:Self) -> Self 
    {
        return .init(
            Scalar.atan(x.x), Scalar.atan(x.y)
            )
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 62)
}
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 51)
extension SIMD3 where Scalar:ElementaryFunctions
{
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 54)
    static 
    func sqrt(_ x:Self) -> Self 
    {
        return .init(
            Scalar.sqrt(x.x), Scalar.sqrt(x.y), Scalar.sqrt(x.z)
            )
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 54)
    static 
    func log(_ x:Self) -> Self 
    {
        return .init(
            Scalar.log(x.x), Scalar.log(x.y), Scalar.log(x.z)
            )
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 54)
    static 
    func exp(_ x:Self) -> Self 
    {
        return .init(
            Scalar.exp(x.x), Scalar.exp(x.y), Scalar.exp(x.z)
            )
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 54)
    static 
    func sin(_ x:Self) -> Self 
    {
        return .init(
            Scalar.sin(x.x), Scalar.sin(x.y), Scalar.sin(x.z)
            )
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 54)
    static 
    func cos(_ x:Self) -> Self 
    {
        return .init(
            Scalar.cos(x.x), Scalar.cos(x.y), Scalar.cos(x.z)
            )
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 54)
    static 
    func tan(_ x:Self) -> Self 
    {
        return .init(
            Scalar.tan(x.x), Scalar.tan(x.y), Scalar.tan(x.z)
            )
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 54)
    static 
    func asin(_ x:Self) -> Self 
    {
        return .init(
            Scalar.asin(x.x), Scalar.asin(x.y), Scalar.asin(x.z)
            )
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 54)
    static 
    func acos(_ x:Self) -> Self 
    {
        return .init(
            Scalar.acos(x.x), Scalar.acos(x.y), Scalar.acos(x.z)
            )
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 54)
    static 
    func atan(_ x:Self) -> Self 
    {
        return .init(
            Scalar.atan(x.x), Scalar.atan(x.y), Scalar.atan(x.z)
            )
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 62)
}
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 51)
extension SIMD4 where Scalar:ElementaryFunctions
{
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 54)
    static 
    func sqrt(_ x:Self) -> Self 
    {
        return .init(
            Scalar.sqrt(x.x), Scalar.sqrt(x.y), Scalar.sqrt(x.z), Scalar.sqrt(x.w)
            )
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 54)
    static 
    func log(_ x:Self) -> Self 
    {
        return .init(
            Scalar.log(x.x), Scalar.log(x.y), Scalar.log(x.z), Scalar.log(x.w)
            )
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 54)
    static 
    func exp(_ x:Self) -> Self 
    {
        return .init(
            Scalar.exp(x.x), Scalar.exp(x.y), Scalar.exp(x.z), Scalar.exp(x.w)
            )
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 54)
    static 
    func sin(_ x:Self) -> Self 
    {
        return .init(
            Scalar.sin(x.x), Scalar.sin(x.y), Scalar.sin(x.z), Scalar.sin(x.w)
            )
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 54)
    static 
    func cos(_ x:Self) -> Self 
    {
        return .init(
            Scalar.cos(x.x), Scalar.cos(x.y), Scalar.cos(x.z), Scalar.cos(x.w)
            )
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 54)
    static 
    func tan(_ x:Self) -> Self 
    {
        return .init(
            Scalar.tan(x.x), Scalar.tan(x.y), Scalar.tan(x.z), Scalar.tan(x.w)
            )
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 54)
    static 
    func asin(_ x:Self) -> Self 
    {
        return .init(
            Scalar.asin(x.x), Scalar.asin(x.y), Scalar.asin(x.z), Scalar.asin(x.w)
            )
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 54)
    static 
    func acos(_ x:Self) -> Self 
    {
        return .init(
            Scalar.acos(x.x), Scalar.acos(x.y), Scalar.acos(x.z), Scalar.acos(x.w)
            )
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 54)
    static 
    func atan(_ x:Self) -> Self 
    {
        return .init(
            Scalar.atan(x.x), Scalar.atan(x.y), Scalar.atan(x.z), Scalar.atan(x.w)
            )
    }
// ###sourceLocation(file: "/swift/diannamy-engine/sources/atmospheric-scattering/elementary-functions.swift.gyb", line: 62)
}
