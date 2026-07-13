//
//  CVDSimulator.swift
//  colorblindapp
//

import Foundation

/// Simula cómo percibe un color un dicrómata (Viénot 1999): RGB lineal → LMS,
/// se sustituye la respuesta del cono ausente por una combinación de los
/// otros dos, y se vuelve a RGB. Es la misma base científica que los pares
/// de confusión del test.
nonisolated enum CVDSimulator {
    private typealias Matrix = (
        (Double, Double, Double),
        (Double, Double, Double),
        (Double, Double, Double)
    )

    private static let rgbToLMS: Matrix = (
        (17.8824, 43.5161, 4.11935),
        (3.45565, 27.1554, 3.86714),
        (0.0299566, 0.184309, 1.46709)
    )

    // Inversa de rgbToLMS, precalculada.
    private static let lmsToRGB: Matrix = (
        (0.080944, -0.130504, 0.116721),
        (-0.010249, 0.054019, -0.113615),
        (-0.000365, -0.004122, 0.693511)
    )

    private static func apply(_ m: Matrix, _ v: (Double, Double, Double)) -> (Double, Double, Double) {
        (
            m.0.0 * v.0 + m.0.1 * v.1 + m.0.2 * v.2,
            m.1.0 * v.0 + m.1.1 * v.1 + m.1.2 * v.2,
            m.2.0 * v.0 + m.2.1 * v.1 + m.2.2 * v.2
        )
    }

    /// Cómo vería `color` una persona con el tipo de daltonismo dado.
    static func simulate(_ color: LinearRGB, type: ColorVisionType) -> LinearRGB {
        guard type != .normal else { return color }

        let lms = apply(rgbToLMS, (color.red, color.green, color.blue))
        let adjusted: (Double, Double, Double)
        switch type {
        case .protan:
            adjusted = (2.02344 * lms.1 - 2.52581 * lms.2, lms.1, lms.2)
        case .deutan:
            adjusted = (lms.0, 0.494207 * lms.0 + 1.24827 * lms.2, lms.2)
        case .tritan:
            adjusted = (lms.0, lms.1, -0.395913 * lms.0 + 0.801109 * lms.1)
        case .normal:
            adjusted = lms
        }

        let rgb = apply(lmsToRGB, adjusted)
        return LinearRGB(
            red: min(max(rgb.0, 0), 1),
            green: min(max(rgb.1, 0), 1),
            blue: min(max(rgb.2, 0), 1)
        )
    }
}
