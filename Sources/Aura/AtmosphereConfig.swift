public import Ion
public import SystemPackage
import struct Foundation.Data
import struct Foundation.URL
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder

public struct AtmosphereConfig: Sendable, Codable {
    public var name: String

    // Geometry
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
        let fileData: Data = try Data(contentsOf: URL(fileURLWithPath: path.string))

        // 1. Binary Ion (magic header: 0xE0 0x01 0x00 0xEA)
        if fileData.count >= 4 &&
           fileData[0] == 0xe0 && fileData[1] == 0x01 && fileData[2] == 0x00 && fileData[3] == 0xea {
            let ion: Ion = .init(bytes: ArraySlice(fileData))
            return try ion.decode(atomic: AtmosphereConfig.self)
        }

        // 2. Ion / JSON text
        guard let text: String = String(data: fileData, encoding: .utf8) else {
            throw AtmosphereError.invalidConfigFile("File is not valid UTF-8 text or binary Ion: '\(path)'")
        }

        let sanitizedJSON: String = sanitizeIonText(text)
        guard let jsonData: Data = sanitizedJSON.data(using: .utf8) else {
            throw AtmosphereError.invalidConfigFile("Failed to encode sanitized JSON from '\(path)'")
        }

        return try JSONDecoder().decode(AtmosphereConfig.self, from: jsonData)
    }

    public static func sanitizeIonText(_ text: String) -> String {
        var lines: [String] = []
        for line in text.components(separatedBy: .newlines) {
            var trimmed: String = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("//") {
                continue
            }
            if let commentRange: Range<String.Index> = trimmed.range(of: "//") {
                trimmed = String(trimmed[..<commentRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            }
            if trimmed.isEmpty {
                continue
            }

            var processed: String = trimmed
            if let colonIdx: String.Index = processed.firstIndex(of: ":") {
                let prefix: String = processed[..<colonIdx].trimmingCharacters(in: .whitespaces)
                let suffix: Substring = processed[colonIdx...]
                if !prefix.hasPrefix("\"") && !prefix.contains(" ") && !prefix.contains("{") && !prefix.contains("}") {
                    let indent: Substring = line.prefix(while: { $0.isWhitespace })
                    processed = "\(indent)\"\(prefix)\"\(suffix)"
                }
            }
            lines.append(processed)
        }
        var cleaned: String = lines.joined(separator: "\n")

        // Remove trailing commas before closing braces or brackets: , } -> } and , ] -> ]
        cleaned = cleaned.replacing(#/,\s*([\}\]])/#) { match in String(match.output.1) }

        return cleaned
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
        if let extinction = self.mie_extinction {
            output += "    mie_extinction: \(extinction),\n"
        }
        if let albedo = self.mie_albedo {
            output += "    mie_albedo: \(albedo),\n"
        }
        output += "    mie_g: \(self.mie_g),\n\n"
        if let ozone = self.ozone_extinction {
            output += "    // Absorption / Ozone layer\n"
            output += "    ozone_extinction: \(ozone),\n"
            if let alt = self.ozone_altitude {
                output += "    ozone_altitude: \(alt),\n"
            }
            if let thick = self.ozone_thickness {
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

extension AtmosphereConfig {
    public static let earth: AtmosphereConfig = .init(
        name: "Earth",
        radius_bottom: 6.36e6,
        radius_top: 6.42e6,
        sun_angular_radius: 0.004675,
        max_sun_zenith_angle: 102.0,
        rayleigh_scale_height: 8000.0,
        rayleigh_scattering: [5.8023393817123834e-06, 1.3557762447920223e-05, 3.3100005976367735e-05],
        mie_scale_height: 1200.0,
        mie_scattering: [3.996e-06, 3.996e-06, 3.996e-06],
        mie_extinction: [4.44e-06, 4.44e-06, 4.44e-06],
        mie_albedo: 0.9,
        mie_g: 0.8,
        ozone_extinction: [7.206534e-07, 1.7710017e-06, 6.5216177e-08],
        ozone_altitude: 25000.0,
        ozone_thickness: 15000.0,
        solar_irradiance: [1.49265, 1.850945, 1.7622550000000001],
        ground_albedo: [0.1, 0.1, 0.1]
    )

    public static let venus: AtmosphereConfig = .init(
        name: "Venus",
        radius_bottom: 6.052e6,
        radius_top: 6.150e6,
        sun_angular_radius: 0.006466,
        max_sun_zenith_angle: 105.0,
        rayleigh_scale_height: 15900.0,
        rayleigh_scattering: [1.95e-5, 4.60e-5, 1.12e-4],
        mie_scale_height: 4000.0,
        mie_scattering: [3.0e-5, 3.0e-5, 2.5e-5],
        mie_extinction: [3.03e-5, 3.03e-5, 2.55e-5],
        mie_albedo: 0.99,
        mie_g: 0.75,
        ozone_extinction: nil,
        solar_irradiance: [2.855, 3.541, 3.371],
        ground_albedo: [0.1, 0.1, 0.1]
    )

    public static let mars: AtmosphereConfig = .init(
        name: "Mars",
        radius_bottom: 3.3895e6,
        radius_top: 3.450e6,
        sun_angular_radius: 0.003067,
        max_sun_zenith_angle: 100.0,
        rayleigh_scale_height: 11100.0,
        rayleigh_scattering: [1.9e-7, 4.5e-7, 1.1e-6],
        mie_scale_height: 2000.0,
        mie_scattering: [4.0e-6, 3.2e-6, 2.0e-6],
        mie_extinction: [4.5e-6, 3.8e-6, 2.8e-6],
        mie_albedo: 0.85,
        mie_g: 0.70,
        ozone_extinction: nil,
        solar_irradiance: [0.642, 0.796, 0.758],
        ground_albedo: [0.25, 0.15, 0.10]
    )

    public static let titan: AtmosphereConfig = .init(
        name: "Titan",
        radius_bottom: 2.575e6,
        radius_top: 2.900e6,
        sun_angular_radius: 0.000489,
        max_sun_zenith_angle: 108.0,
        rayleigh_scale_height: 40000.0,
        rayleigh_scattering: [2.5e-5, 5.8e-5, 1.4e-4],
        mie_scale_height: 20000.0,
        mie_scattering: [2.0e-5, 1.5e-5, 8.0e-6],
        mie_extinction: [2.5e-5, 2.2e-5, 1.6e-5],
        mie_albedo: 0.80,
        mie_g: 0.85,
        ozone_extinction: nil,
        solar_irradiance: [0.0163, 0.0202, 0.0192],
        ground_albedo: [0.15, 0.15, 0.15]
    )
}
