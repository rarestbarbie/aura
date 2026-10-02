<div align="center">

🪐 &nbsp; **aura** &nbsp; 🪐

a swift library abd command-line tool for precomputing multi-spectral atmospheric scattering tables

[documentation and api reference](https://swiftinit.org/docs/aura)

</div>


## Requirements

The aura library requires Swift 6.2 or later.

<!-- DO NOT EDIT BELOW! AUTOSYNC CONTENT [STATUS TABLE] -->
| Platform | Status |
| -------- | ------ |
| 🐧 Linux | [![Status](https://raw.githubusercontent.com/rarestype/aura/refs/badges/ci/Tests/Linux/status.svg)](https://github.com/rarestype/aura/actions/workflows/Tests.yml) |
| 🍏 Darwin | [![Status](https://raw.githubusercontent.com/rarestype/aura/refs/badges/ci/Tests/macOS/status.svg)](https://github.com/rarestype/aura/actions/workflows/Tests.yml) |
| 💝 macOS | [![Status](https://raw.githubusercontent.com/rarestype/aura/refs/badges/ci/SemanticRelease/macOS/status.svg)](https://github.com/rarestype/aura/actions/workflows/SemanticRelease.yml) |
| 💝 Linux (aarch64) | [![Status](https://raw.githubusercontent.com/rarestype/aura/refs/badges/ci/SemanticRelease/Linux-aarch64/status.svg)](https://github.com/rarestype/aura/actions/workflows/SemanticRelease.yml) |
| 💝 Linux (x86_64) | [![Status](https://raw.githubusercontent.com/rarestype/aura/refs/badges/ci/SemanticRelease/Linux-x86_64/status.svg)](https://github.com/rarestype/aura/actions/workflows/SemanticRelease.yml) |
<!-- DO NOT EDIT ABOVE! AUTOSYNC CONTENT [STATUS TABLE] -->

[Check deployment minimums](https://swiftinit.org/docs/aura#ss:platform-requirements)


## Features

Aura implements Eric Bruneton’s multiple atmospheric scattering model, generating precomputed lookup tables for:

- Optical transmittance (`transmittance.bin`)
- Single and multiple Rayleigh and Mie scattering (`scattering.bin`)
- Ground and sky irradiance (`irradiance.bin`)
- Atmospheric parameter uniforms for WebGL and shader pipelines (`parameters.json`)

It supports:

- **Parameterized planetary atmospheres**: Configure arbitrary planets (Earth, Venus, Mars, Titan) using Ion (`.ion`) or JSON (`.json`) configuration files.
- **Built-in presets**: Ready-to-bake atmospheric presets for Earth, Venus, Mars, and Titan.
- **Binary table packaging**: Directly emits IEEE-754 little-endian single-precision Float32 buffers optimized for GPU texture uploads (`Float32Array` in WebGL / Three.js).
- **Ion configuration support**: Reads native binary Ion (`IonABI`) as well as human-readable Ion text files with comments, unquoted keys, and trailing commas.

## Command-line usage

### Bake an atmosphere using a built-in preset

```bash
aura --preset earth --detail 3 --output Public/Earth/Atmosphere
```

Available presets:
- `earth`
- `venus`
- `mars`
- `titan`

### Bake an atmosphere using an Ion configuration file

```bash
aura --config Presets/Venus.ion --detail 3 --output Public/Venus/Atmosphere
```

### Options

- `-p, --preset <name>`: Built-in planetary preset name (`earth`, `venus`, `mars`, `titan`).
- `-c, --config <path>`: Path to an Ion (`.ion`) or JSON (`.json`) configuration file.
- `-d, --detail <level>`: Level of detail (1 to 5, default 3). Higher detail exponentially increases table resolution.
- `-o, --output <directory>`: Target directory for the generated tables.

## Configuration format

Atmospheric configurations can be defined in Ion (`.ion`) files:

```ion
{
    // Atmosphere configuration for Earth
    name: "Earth",

    // Planetary geometry (meters and radians)
    radius_bottom: 6360000.0,
    radius_top: 6420000.0,
    sun_angular_radius: 0.004675,
    max_sun_zenith_angle: 102.0,

    // Rayleigh molecular scattering
    rayleigh_scale_height: 8000.0,
    rayleigh_scattering: [5.802339e-06, 1.355776e-05, 3.310001e-05],

    // Mie aerosol scattering
    mie_scale_height: 1200.0,
    mie_scattering: [3.996e-06, 3.996e-06, 3.996e-06],
    mie_extinction: [4.44e-06, 4.44e-06, 4.44e-06],
    mie_albedo: 0.9,
    mie_g: 0.8,

    // Optional absorption / ozone layer (tent profile)
    ozone_extinction: [7.206534e-07, 1.771002e-06, 6.521618e-08],
    ozone_altitude: 25000.0,
    ozone_thickness: 15000.0,

    // Illumination and surface reflectance
    solar_irradiance: [1.49265, 1.850945, 1.762255],
    ground_albedo: [0.1, 0.1, 0.1],
}
```
