//
//  ColorNamer.swift
//  colorblindapp
//

import Foundation

/// Clasifica un color en una categoría básica ("Verde", "Marrón"…) a partir
/// de tono, saturación y luminosidad, y en un nombre descriptivo fino
/// ("Verde oliva") vía el catálogo y ΔE.
/// `nonisolated`: matemática pura, se usa también desde contextos no aislados.
nonisolated enum ColorNamer {
    /// Nombre descriptivo fino ("Verde oliva"): el más cercano del catálogo
    /// curado por distancia en Lab.
    static func descriptiveName(for color: LinearRGB) -> String {
        ColorCatalog.closestName(to: color)
    }

    /// Aviso de confusión: si al simular el color con el daltonismo del
    /// usuario la categoría básica cambia, devuelve la categoría que el
    /// usuario probablemente percibe. nil si no hay confusión esperable.
    static func perceivedName(for color: LinearRGB, visionType: ColorVisionType) -> String? {
        guard visionType != .normal else { return nil }
        let simulated = CVDSimulator.simulate(color, type: visionType)
        let original = basicName(for: color)
        let perceived = basicName(for: simulated)
        return perceived == original ? nil : perceived
    }

    static func basicName(for color: LinearRGB) -> String {
        let (hue, saturation, lightness) = color.hsl

        // Acromáticos primero: el tono no es fiable con saturación baja.
        if lightness < 0.09 { return String(localized: "Negro") }
        if lightness > 0.93 && saturation < 0.25 { return String(localized: "Blanco") }
        if saturation < 0.10 { return String(localized: "Gris") }

        switch hue {
        case ..<12, 347...:
            return lightness > 0.72 ? String(localized: "Rosa") : String(localized: "Rojo")
        case ..<40:
            if lightness < 0.36 { return String(localized: "Marrón") }
            if lightness > 0.68 && saturation < 0.55 { return String(localized: "Beige") }
            return String(localized: "Naranja")
        case ..<68:
            return lightness < 0.28 ? String(localized: "Marrón") : String(localized: "Amarillo")
        case ..<165:
            return String(localized: "Verde")
        case ..<200:
            return String(localized: "Turquesa")
        case ..<260:
            return String(localized: "Azul")
        case ..<295:
            return String(localized: "Morado")
        default:
            return lightness > 0.55 ? String(localized: "Rosa") : String(localized: "Morado")
        }
    }
}
