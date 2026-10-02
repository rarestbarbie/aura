package struct AtmosphereParameters: Sendable, Codable {
    package var radius_bottom: Float
    package var radius_top: Float
    package var radius_sun: Float
    package var mu_s_min: Float
    package var rayleigh_scattering: [Float]
    package var mie_scattering: [Float]
    package var mie_g: Float
    package var resolution_transmittance: [Int]
    package var resolution_scattering4_R: Int
    package var resolution_scattering4_M: Int
    package var resolution_scattering4_MS: Int
    package var resolution_scattering4_N: Int
    package var resolution_irradiance: [Int]
    package var irradiance: [Float]

    package init(
        radius_bottom: Float,
        radius_top: Float,
        radius_sun: Float,
        mu_s_min: Float,
        rayleigh_scattering: [Float],
        mie_scattering: [Float],
        mie_g: Float,
        resolution_transmittance: [Int],
        resolution_scattering4_R: Int,
        resolution_scattering4_M: Int,
        resolution_scattering4_MS: Int,
        resolution_scattering4_N: Int,
        resolution_irradiance: [Int],
        irradiance: [Float]
    ) {
        self.radius_bottom = radius_bottom
        self.radius_top = radius_top
        self.radius_sun = radius_sun
        self.mu_s_min = mu_s_min
        self.rayleigh_scattering = rayleigh_scattering
        self.mie_scattering = mie_scattering
        self.mie_g = mie_g
        self.resolution_transmittance = resolution_transmittance
        self.resolution_scattering4_R = resolution_scattering4_R
        self.resolution_scattering4_M = resolution_scattering4_M
        self.resolution_scattering4_MS = resolution_scattering4_MS
        self.resolution_scattering4_N = resolution_scattering4_N
        self.resolution_irradiance = resolution_irradiance
        self.irradiance = irradiance
    }
}
