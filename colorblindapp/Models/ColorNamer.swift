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

        // Acromáticos primero, decididos por croma de Lab: la saturación
        // HSL engaña en colores oscuros apagados (un caqui oscuro baja del
        // 10% de saturación pero su croma perceptual sigue siendo verdoso).
        let lab = color.lab
        let chroma = (lab.a * lab.a + lab.b * lab.b).squareRoot()
        if lightness < 0.09 { return String(localized: "Negro") }
        if lightness > 0.93 && chroma < 12 { return String(localized: "Blanco") }
        // El croma perceptual se comprime cerca del negro (Lab tiene menos
        // rango de a/b a luminosidad baja): un umbral fijo de 8 cuela como
        // "Gris" tintes oscuros reales (un verde militar o un marrón muy
        // oscuro) que sí se perciben con color. Para eso existe la app —
        // para revelarle al usuario justo el matiz que no puede verificar
        // a ojo — así que en oscuros exigimos menos croma para dejarlo pasar.
        let grayThreshold = lightness < 0.3 ? 4.0 : 8.0
        if chroma < grayThreshold { return String(localized: "Gris") }

        switch hue {
        case ..<12, 347...:
            return lightness > 0.72 ? String(localized: "Rosa") : String(localized: "Rojo")
        case ..<40:
            if lightness < 0.36 { return String(localized: "Marrón") }
            // Un tono cálido con poca saturación es beige/topo aunque no sea
            // muy claro (p. ej. un pantalón de lino topo a media luz): la
            // saturación manda sobre la luminosidad para decidir "Beige".
            if saturation < 0.35 || (lightness > 0.68 && saturation < 0.55) {
                return String(localized: "Beige")
            }
            return String(localized: "Naranja")
        case ..<68:
            if lightness < 0.28 { return String(localized: "Marrón") }
            // Banda oliva: amarillo verdoso apagado y medio-oscuro es lo
            // que la gente llama caqui o verde militar.
            if hue >= 52 && saturation < 0.5 && lightness < 0.5 { return String(localized: "Verde") }
            // Mismo caso que en la franja anterior: pálido y poco saturado
            // es beige/crema/hueso, no amarillo.
            if saturation < 0.35 || (lightness > 0.68 && saturation < 0.55) {
                return String(localized: "Beige")
            }
            return String(localized: "Amarillo")
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
