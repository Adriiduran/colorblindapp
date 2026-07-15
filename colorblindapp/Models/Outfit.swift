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

    /// Nº de prendas con las que se guardó el outfit. Al borrar una prenda,
    /// `deleteRule: .nullify` la quita de `garments` en vez de borrar el
    /// outfit entero: comparar contra este valor es cómo detectamos que el
    /// outfit se quedó incompleto, sin necesitar borrarlo.
    var originalGarmentCount: Int = 0

    init(garments: [Garment], score: Double, explanation: String) {
        self.garments = garments
        self.score = score
        self.explanation = explanation
        self.createdAt = .now
        self.originalGarmentCount = garments.count
    }

    /// Al usuario se le quitó al menos una prenda de este outfit desde que lo
    /// guardó (la borró del armario). Los outfits guardados antes de esta
    /// versión no tienen `originalGarmentCount` fiable y nunca se marcan así.
    var isIncomplete: Bool {
        originalGarmentCount > 0 && garments.count < originalGarmentCount
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
