//
//  Outfit.swift
//  colorblindapp
//

import Foundation
import SwiftData

/// Un outfit guardado por el usuario: las prendas que lo componen más la
/// puntuación y la explicación que dio el motor al proponerlo.
@Model
final class Outfit {
    @Relationship(deleteRule: .nullify, inverse: \Garment.outfits)
    var garments: [Garment]

    /// Puntuación del motor en rango 0-100.
    var score: Double
    var explanation: String
    var createdAt: Date

    /// Última vez que el usuario marcó el outfit como puesto ("usado hoy").
    var lastWornAt: Date?

    init(garments: [Garment], score: Double, explanation: String) {
        self.garments = garments
        self.score = score
        self.explanation = explanation
        self.createdAt = .now
    }

    /// Prendas en orden de presentación; SwiftData no conserva el orden del
    /// array, así que se reordena por el hueco que ocupa cada prenda.
    var sortedGarments: [Garment] {
        garments.sorted { ($0.category.outfitSlot ?? .top) < ($1.category.outfitSlot ?? .top) }
    }

    var wornToday: Bool {
        guard let lastWornAt else { return false }
        return Calendar.current.isDateInToday(lastWornAt)
    }
}
