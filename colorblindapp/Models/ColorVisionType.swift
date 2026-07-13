//
//  ColorVisionType.swift
//  colorblindapp
//

import Foundation

/// Tipo de visión del color del usuario, detectado en el test de onboarding
/// o elegido manualmente.
enum ColorVisionType: String, Codable, CaseIterable, Identifiable {
    case normal
    case protan
    case deutan
    case tritan

    var id: String { rawValue }

    /// Nombre corto para mostrar en la interfaz.
    var displayName: String {
        switch self {
        case .normal: String(localized: "Visión normal")
        case .protan: String(localized: "Protán (rojo)")
        case .deutan: String(localized: "Deután (verde)")
        case .tritan: String(localized: "Tritán (azul-amarillo)")
        }
    }

    /// Explicación en lenguaje llano de qué colores se confunden.
    var summary: String {
        switch self {
        case .normal:
            String(localized: "Distingues los colores con normalidad.")
        case .protan:
            String(localized: "Tienes dificultad con los rojos: pueden parecerte más oscuros o confundirse con verdes y marrones.")
        case .deutan:
            String(localized: "Tienes dificultad con los verdes: pueden confundirse con rojos, marrones y naranjas. Es el tipo más común.")
        case .tritan:
            String(localized: "Tienes dificultad con azules y amarillos: los azules pueden confundirse con verdes y los amarillos con rosas o grises.")
        }
    }
}

/// Severidad aproximada del daltonismo.
enum ColorVisionSeverity: String, Codable, CaseIterable, Identifiable {
    /// Anomalía leve o moderada (p. ej. deuteranomalía).
    case mild
    /// Ausencia total del tipo de cono (p. ej. deuteranopia).
    case strong
    /// Elegido manualmente sin test, o test no concluyente.
    case unknown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mild: String(localized: "Leve o moderada")
        case .strong: String(localized: "Fuerte")
        case .unknown: String(localized: "Sin determinar")
        }
    }
}
