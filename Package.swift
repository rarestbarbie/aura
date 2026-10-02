// swift-tools-version:6.2
import PackageDescription

let package: Package = .init(
    name: "aura",
    platforms: [.macOS(.v15), .iOS(.v18), .tvOS(.v18), .visionOS(.v2), .watchOS(.v11)],
    products: [
        .executable(name: "aura", targets: ["AuraCLI"]),
        .library(name: "Aura", targets: ["Aura"]),
    ],
    dependencies: [
        .package(url: "https://github.com/rarestype/swift-io", from: "3.2.0"),
        .package(url: "https://github.com/rarestype/swift-ion", from: "2.0.0"),
        .package(url: "https://github.com/rarestype/swift-json", from: "3.5.0"),
    ],
    targets: [
        .target(
            name: "CZlib",
            linkerSettings: [.linkedLibrary("z")]
        ),
        .target(
            name: "Aura",
            dependencies: [
                .target(name: "CZlib"),
                .product(name: "Ion", package: "swift-ion"),
                .product(name: "JSON", package: "swift-json"),
                .product(name: "SystemIO", package: "swift-io"),
            ]
        ),
        .executableTarget(
            name: "AuraCLI",
            dependencies: [
                .target(name: "Aura"),
                .product(name: "System_ArgumentParser", package: "swift-io"),
            ]
        ),
        .testTarget(
            name: "AuraTests",
            dependencies: [
                .target(name: "Aura"),
            ]
        ),
    ]
)

for target: Target in package.targets {
    {
        var settings: [SwiftSetting] = $0 ?? []
        settings.append(.enableUpcomingFeature("ExistentialAny"))
        $0 = settings
    } (&target.swiftSettings)
}
