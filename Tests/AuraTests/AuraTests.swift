import Foundation
import Testing
import Ion
@testable import Aura

@Suite struct AuraTests {
    @Test static func earthParametersMatch() {
        let resolutions = (
            transmittance: Vector2<Int>(32, 8)       &<< 1,
            scattering:    Vector4<Int>(4, 16, 4, 1) &<< 1,
            irradiance:    Vector2<Int>(8, 2)        &<< 1
        )
        let ref = Atmosphere<Double>.earth(resolutions: resolutions)
        let parameterized = Atmosphere<Double>.from(config: .earth, resolutions: resolutions)

        #expect(ref.serialized == parameterized.serialized)
        #expect(ref.ground == parameterized.ground)
        #expect(ref.absorption.extinction == parameterized.absorption.extinction)
    }

    @Test static func ionBinaryRoundtrip() throws {
        let config = AtmosphereConfig.earth
        let ion: Ion = .encode(atomic: config)
        let decoded: AtmosphereConfig = try ion.decode(atomic: AtmosphereConfig.self)

        #expect(decoded.name == "Earth")
        #expect(decoded.radius_bottom == config.radius_bottom)
        #expect(decoded.radius_top == config.radius_top)
        #expect(decoded.rayleigh_scattering == config.rayleigh_scattering)
        #expect(decoded.mie_scattering == config.mie_scattering)
    }

    @Test static func ionTextParsing() throws {
        let text = """
        {
            // Earth atmosphere configuration
            name: "Earth",
            radius_bottom: 6360000.0,
            radius_top: 6420000.0,
            sun_angular_radius: 0.004675,
            max_sun_zenith_angle: 102.0,
            rayleigh_scale_height: 8000.0,
            rayleigh_scattering: [5.8023393817123834e-06, 1.3557762447920223e-05, 3.3100005976367735e-05],
            mie_scale_height: 1200.0,
            mie_scattering: [3.996e-06, 3.996e-06, 3.996e-06],
            mie_extinction: [4.44e-06, 4.44e-06, 4.44e-06],
            mie_albedo: 0.9,
            mie_g: 0.8,
            solar_irradiance: [1.49265, 1.850945, 1.762255],
            ground_albedo: [0.1, 0.1, 0.1],
        }
        """

        let sanitized = AtmosphereConfig.sanitizeIonText(text)
        guard let data = sanitized.data(using: .utf8) else {
            Issue.record("Failed to convert sanitized string to UTF-8 data")
            return
        }
        let config = try JSONDecoder().decode(AtmosphereConfig.self, from: data)
        #expect(config.name == "Earth")
        #expect(config.radius_bottom == 6360000.0)
        #expect(config.mie_g == 0.8)
    }
}
