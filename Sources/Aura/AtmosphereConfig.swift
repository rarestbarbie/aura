public import Ion
import SystemIO
public import SystemPackage

public struct AtmosphereConfig: Sendable {
    public var name: String

    // Planetary geometry (meters and degrees)
    public var radius_bottom: Double
    public var radius_top: Double
    public var sun_angular_radius: Double
    public var max_sun_zenith_angle: Double

    // Rayleigh scattering (molecular gas)
    public var rayleigh_scale_height: Double
    public var rayleigh_scattering: [Double]

    // Mie scattering (aerosols / haze)
    public var mie_scale_height: Double
    public var mie_scattering: [Double]
    public var mie_extinction: [Double]?
    public var mie_albedo: Double?
    public var mie_g: Double

    // Ozone absorption (tent profile)
    public var ozone_extinction: [Double]?
    public var ozone_altitude: Double?
    public var ozone_thickness: Double?

    // Illumination
    public var solar_irradiance: [Double]
    public var ground_albedo: [Double]

    public init(
        name: String,
        radius_bottom: Double,
        radius_top: Double,
        sun_angular_radius: Double,
        max_sun_zenith_angle: Double,
        rayleigh_scale_height: Double,
        rayleigh_scattering: [Double],
        mie_scale_height: Double,
        mie_scattering: [Double],
        mie_extinction: [Double]? = nil,
        mie_albedo: Double? = 0.9,
        mie_g: Double = 0.8,
        ozone_extinction: [Double]? = nil,
        ozone_altitude: Double? = nil,
        ozone_thickness: Double? = nil,
        solar_irradiance: [Double],
        ground_albedo: [Double]
    ) {
        self.name = name
        self.radius_bottom = radius_bottom
        self.radius_top = radius_top
        self.sun_angular_radius = sun_angular_radius
        self.max_sun_zenith_angle = max_sun_zenith_angle
        self.rayleigh_scale_height = rayleigh_scale_height
        self.rayleigh_scattering = rayleigh_scattering
        self.mie_scale_height = mie_scale_height
        self.mie_scattering = mie_scattering
        self.mie_extinction = mie_extinction
        self.mie_albedo = mie_albedo
        self.mie_g = mie_g
        self.ozone_extinction = ozone_extinction
        self.ozone_altitude = ozone_altitude
        self.ozone_thickness = ozone_thickness
        self.solar_irradiance = solar_irradiance
        self.ground_albedo = ground_albedo
    }
}

extension AtmosphereConfig {
    @frozen public enum CodingKey: String, IonSymbolizable {
        case name
        case radius_bottom
        case radius_top
        case sun_angular_radius
        case max_sun_zenith_angle
        case rayleigh_scale_height
        case rayleigh_scattering
        case mie_scale_height
        case mie_scattering
        case mie_extinction
        case mie_albedo
        case mie_g
        case ozone_extinction
        case ozone_altitude
        case ozone_thickness
        case solar_irradiance
        case ground_albedo
    }
}

extension AtmosphereConfig: IonEncodableStruct {
    public func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.name] = self.name
        ion[.radius_bottom] = self.radius_bottom
        ion[.radius_top] = self.radius_top
        ion[.sun_angular_radius] = self.sun_angular_radius
        ion[.max_sun_zenith_angle] = self.max_sun_zenith_angle
        ion[.rayleigh_scale_height] = self.rayleigh_scale_height
        ion[.rayleigh_scattering] = self.rayleigh_scattering
        ion[.mie_scale_height] = self.mie_scale_height
        ion[.mie_scattering] = self.mie_scattering
        ion[.mie_extinction] = self.mie_extinction
        ion[.mie_albedo] = self.mie_albedo
        ion[.mie_g] = self.mie_g
        ion[.ozone_extinction] = self.ozone_extinction
        ion[.ozone_altitude] = self.ozone_altitude
        ion[.ozone_thickness] = self.ozone_thickness
        ion[.solar_irradiance] = self.solar_irradiance
        ion[.ground_albedo] = self.ground_albedo
    }
}

extension AtmosphereConfig: IonDecodableStruct {
    public init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        self.init(
            name: try ion[.name]?.decode() ?? "Unnamed",
            radius_bottom: try ion[.radius_bottom].decode(),
            radius_top: try ion[.radius_top].decode(),
            sun_angular_radius: try ion[.sun_angular_radius]?.decode() ?? 0.004675,
            max_sun_zenith_angle: try ion[.max_sun_zenith_angle]?.decode() ?? 102.0,
            rayleigh_scale_height: try ion[.rayleigh_scale_height].decode(),
            rayleigh_scattering: try ion[.rayleigh_scattering].decode(),
            mie_scale_height: try ion[.mie_scale_height].decode(),
            mie_scattering: try ion[.mie_scattering].decode(),
            mie_extinction: try ion[.mie_extinction]?.decode(),
            mie_albedo: try ion[.mie_albedo]?.decode() ?? 0.9,
            mie_g: try ion[.mie_g]?.decode() ?? 0.8,
            ozone_extinction: try ion[.ozone_extinction]?.decode(),
            ozone_altitude: try ion[.ozone_altitude]?.decode(),
            ozone_thickness: try ion[.ozone_thickness]?.decode(),
            solar_irradiance: try ion[.solar_irradiance].decode(),
            ground_albedo: try ion[.ground_albedo]?.decode() ?? [0.1, 0.1, 0.1]
        )
    }
}

extension AtmosphereConfig {
    public static func load(from path: FilePath) throws -> AtmosphereConfig {
        let fileBytes: [UInt8] = try path.read([UInt8].self)

        // 1. Binary Ion (magic header: 0xE0 0x01 0x00 0xEA)
        if fileBytes.count >= 4 &&
            fileBytes[
                0
            ] == 0xe0 && fileBytes[1] == 0x01 && fileBytes[2] == 0x00 && fileBytes[3] == 0xea {
            let ion: Ion = .init(bytes: fileBytes[...])
            return try ion.decode(atomic: AtmosphereConfig.self)
        }

        // 2. Ion text
        let text: String = String(decoding: fileBytes, as: UTF8.self)
        guard !text.isEmpty else {
            throw AtmosphereError.invalidConfigFile(
                "File is empty or not valid UTF-8 text: ‘\(path)’"
            )
        }

        return try parse(ion: text)
    }

    public static func parse(ion text: String) throws -> AtmosphereConfig {
        var cleanText: String = ""
        for line: Substring in text.split(whereSeparator: \.isNewline) {
            var trimmed: Substring = line[...]
            if let commentRange: Range<Substring.Index> = trimmed.firstRange(of: "//") {
                trimmed = trimmed[..<commentRange.lowerBound]
            }
            cleanText.append(contentsOf: trimmed)
            cleanText.append(" ")
        }

        var values: [String: String] = [:]
        var index: String.Index = cleanText.startIndex
        while index < cleanText.endIndex {
            if cleanText[index].isWhitespace || cleanText[index] == "{" {
                index = cleanText.index(after: index)
                continue
            }
            if cleanText[index] == "}" {
                break
            }

            let keyStart: String.Index = index
            while index < cleanText.endIndex && cleanText[
                    index
                ] != ":" && !cleanText[index].isWhitespace {
                index = cleanText.index(after: index)
            }
            var key: Substring = cleanText[keyStart ..< index]
            if key.hasPrefix("\"") && key.hasSuffix("\"") && key.count >= 2 {
                key = key.dropFirst().dropLast()
            }

            while index < cleanText.endIndex && cleanText[index].isWhitespace {
                index = cleanText.index(after: index)
            }
            guard index < cleanText.endIndex && cleanText[index] == ":" else {
                break
            }
            index = cleanText.index(after: index)

            while index < cleanText.endIndex && cleanText[index].isWhitespace {
                index = cleanText.index(after: index)
            }
            guard index < cleanText.endIndex else { break }

            let valueStart: String.Index = index
            if cleanText[index] == "[" {
                while index < cleanText.endIndex && cleanText[index] != "]" {
                    index = cleanText.index(after: index)
                }
                if index < cleanText.endIndex && cleanText[index] == "]" {
                    index = cleanText.index(after: index)
                }
            } else if cleanText[index] == "\"" {
                index = cleanText.index(after: index)
                while index < cleanText.endIndex && cleanText[index] != "\"" {
                    index = cleanText.index(after: index)
                }
                if index < cleanText.endIndex && cleanText[index] == "\"" {
                    index = cleanText.index(after: index)
                }
            } else {
                while index < cleanText.endIndex && cleanText[
                        index
                    ] != "," && cleanText[index] != "}" && !cleanText[index].isWhitespace {
                    index = cleanText.index(after: index)
                }
            }

            let val: Substring = cleanText[valueStart ..< index]
            while index < cleanText.endIndex && (
                    cleanText[index] == "," || cleanText[index].isWhitespace
                ) {
                index = cleanText.index(after: index)
            }
            values[String(key)] = String(val)
        }

        func parseDouble(_ key: String) throws -> Double {
            guard let str: String = values[key], let val: Double = Double(str) else {
                throw AtmosphereError.invalidConfigFile(
                    "Missing or invalid double property ‘\(key)’"
                )
            }
            return val
        }

        func parseOptionalDouble(_ key: String, default: Double? = nil) throws -> Double? {
            guard let str: String = values[key] else { return `default` }
            guard let val: Double = Double(str) else {
                throw AtmosphereError.invalidConfigFile("Invalid double property ‘\(key)’")
            }
            return val
        }

        func parseDoubleArray(_ key: String) throws -> [Double] {
            guard let str: String = values[key] else {
                throw AtmosphereError.invalidConfigFile(
                    "Missing double array property ‘\(key)’"
                )
            }
            var trimmed: Substring = str[...]
            if trimmed.hasPrefix("[") { trimmed = trimmed.dropFirst() }
            if trimmed.hasSuffix("]") { trimmed = trimmed.dropLast() }
            let parts: [Substring] = trimmed.split(separator: ",")
            var result: [Double] = []
            result.reserveCapacity(parts.count)
            for part: Substring in parts {
                let partTrimmed: Substring = part.trimmingPrefix(while: \.isWhitespace)
                guard let d: Double = Double(partTrimmed.filter { !$0.isWhitespace }) else {
                    throw AtmosphereError.invalidConfigFile(
                        "Invalid double in array for ‘\(key)’: ‘\(part)’"
                    )
                }
                result.append(d)
            }
            return result
        }

        func parseOptionalDoubleArray(_ key: String) throws -> [Double]? {
            guard values[key] != nil else { return nil }
            return try parseDoubleArray(key)
        }

        func parseString(_ key: String, default: String = "Unnamed") -> String {
            guard let str: String = values[key] else { return `default` }
            var trimmed: Substring = str[...]
            if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") && trimmed.count >= 2 {
                trimmed = trimmed.dropFirst().dropLast()
            }
            return String(trimmed)
        }

        return try AtmosphereConfig(
            name: parseString("name"),
            radius_bottom: parseDouble("radius_bottom"),
            radius_top: parseDouble("radius_top"),
            sun_angular_radius: parseOptionalDouble(
                "sun_angular_radius",
                default: 0.004675
            ) ?? 0.004675,
            max_sun_zenith_angle: parseOptionalDouble(
                "max_sun_zenith_angle",
                default: 102.0
            ) ?? 102.0,
            rayleigh_scale_height: parseDouble("rayleigh_scale_height"),
            rayleigh_scattering: parseDoubleArray("rayleigh_scattering"),
            mie_scale_height: parseDouble("mie_scale_height"),
            mie_scattering: parseDoubleArray("mie_scattering"),
            mie_extinction: parseOptionalDoubleArray("mie_extinction"),
            mie_albedo: parseOptionalDouble("mie_albedo", default: 0.9),
            mie_g: parseOptionalDouble("mie_g", default: 0.8) ?? 0.8,
            ozone_extinction: parseOptionalDoubleArray("ozone_extinction"),
            ozone_altitude: parseOptionalDouble("ozone_altitude"),
            ozone_thickness: parseOptionalDouble("ozone_thickness"),
            solar_irradiance: parseDoubleArray("solar_irradiance"),
            ground_albedo: parseOptionalDoubleArray("ground_albedo") ?? [0.1, 0.1, 0.1]
        )
    }

    public func toIonText() -> String {
        var output: String = "{\n"
        output += "    // Atmosphere configuration for \(self.name)\n"
        output += "    name: \"\(self.name)\",\n\n"
        output += "    // Planetary geometry (meters and radians)\n"
        output += "    radius_bottom: \(self.radius_bottom),\n"
        output += "    radius_top: \(self.radius_top),\n"
        output += "    sun_angular_radius: \(self.sun_angular_radius),\n"
        output += "    max_sun_zenith_angle: \(self.max_sun_zenith_angle),\n\n"
        output += "    // Rayleigh molecular scattering\n"
        output += "    rayleigh_scale_height: \(self.rayleigh_scale_height),\n"
        output += "    rayleigh_scattering: \(self.rayleigh_scattering),\n\n"
        output += "    // Mie aerosol scattering\n"
        output += "    mie_scale_height: \(self.mie_scale_height),\n"
        output += "    mie_scattering: \(self.mie_scattering),\n"
        if let extinction: [Double] = self.mie_extinction {
            output += "    mie_extinction: \(extinction),\n"
        }
        if let albedo: Double = self.mie_albedo {
            output += "    mie_albedo: \(albedo),\n"
        }
        output += "    mie_g: \(self.mie_g),\n\n"
        if let ozone: [Double] = self.ozone_extinction {
            output += "    // Absorption / Ozone layer\n"
            output += "    ozone_extinction: \(ozone),\n"
            if let alt: Double = self.ozone_altitude {
                output += "    ozone_altitude: \(alt),\n"
            }
            if let thick: Double = self.ozone_thickness {
                output += "    ozone_thickness: \(thick),\n"
            }
            output += "\n"
        }
        output += "    // Illumination and surface reflectance\n"
        output += "    solar_irradiance: \(self.solar_irradiance),\n"
        output += "    ground_albedo: \(self.ground_albedo),\n"
        output += "}\n"
        return output
    }
}
