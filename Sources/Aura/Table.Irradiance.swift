struct _TableIrradiance<F>: Table.D2 where F: SwiftFloatingPoint {
    let atmosphere: Atmosphere<F>
    var buffer: [Vector3<F>]

    var size: Vector2<Int> {
        self.atmosphere.resolution.irradiance
    }
}
extension Table.Irradiance {
    subscript(r r: F, μs μs: F) -> Vector3<F> {
        let t: Vector2<F> = self.atmosphere.irradianceTextureCoordinate(r: r, μs: μs)
        return self[t]
    }
}


extension Table.Irradiance: CustomStringConvertible {
    var description: String {
        """
        Irradiance table [\(self.size.x), \(self.size.y)]
        {
        \((0 ..< self.size.y).map {
                (y: Int) in
                return """
                    [\(y)]:
                \((0 ..< self.size.x).map {
                        (x: Int) in

                        let color: Vector3<F> = self.buffer[y * self.size.x + x]
                        return """
                                [\(Highlight.pad("\(x)", left: 3))]: \(
                            Highlight.swatch(color)
                        ) \(
                            color
                        )
                        """
                    }.joined(separator: "\n"))
                """
            }.joined(separator: "\n"))
        }
        """
    }
}
