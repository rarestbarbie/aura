public struct AtmosphereParameters: Sendable, Codable, Equatable {
    public var radius_bottom: Float
    public var radius_top: Float
    public var radius_sun: Float
    public var mu_s_min: Float
    public var rayleigh_scattering: [Float]
    public var mie_scattering: [Float]
    public var mie_g: Float
    public var resolution_transmittance: [Int]
    public var resolution_scattering4_R: Int
    public var resolution_scattering4_M: Int
    public var resolution_scattering4_MS: Int
    public var resolution_scattering4_N: Int
    public var resolution_irradiance: [Int]
    public var irradiance: [Float]

    public init(
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
