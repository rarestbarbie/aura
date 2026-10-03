extension Atmosphere.DensityProfile {
    struct Layer {
        let thickness: F
        let coefficient: (exponential: F, linear: F, constant: F)
        let scale: F

        init(
            thickness: F = 0,
            coefficients: (exponential: F, linear: F, constant: F),
            H: F
        ) {
            self.thickness = thickness
            self.coefficient = coefficients
            self.scale = -1 / H
        }

        subscript(altitude altitude: F) -> F {
            let terms: (F, F, F) = (
                self.coefficient.exponential * F.exp(self.scale * altitude),
                self.coefficient.linear * altitude,
                self.coefficient.constant
            )
            return max(0, min(terms.0 + terms.1 + terms.2, 1))
        }
    }
}
