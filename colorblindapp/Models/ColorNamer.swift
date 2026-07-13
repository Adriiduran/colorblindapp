//
//  ColorNamer.swift
//  colorblindapp
//

import Foundation

/// Clasifica un color en una categoría básica ("Verde", "Marrón"…) a partir
/// de tono, saturación y luminosidad. El nombre descriptivo fino ("Verde
/// oliva") llegará en el hito 4 con el diccionario de colores y ΔE.
enum ColorNamer {
    static func basicName(for color: LinearRGB) -> String {
        let (r, g, b) = color.srgbComponents
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC
        let lightness = (maxC + minC) / 2
        let saturation = delta == 0 ? 0 : delta / (1 - abs(2 * lightness - 1))

        var hue = 0.0
        if delta > 0 {
            switch maxC {
            case r: hue = ((g - b) / delta).truncatingRemainder(dividingBy: 6)
            case g: hue = (b - r) / delta + 2
            default: hue = (r - g) / delta + 4
            }
            hue *= 60
            if hue < 0 { hue += 360 }
        }

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
