//
//  ColorCatalog.swift
//  colorblindapp
//

import Foundation

/// Diccionario curado de colores con nombre en español. El escáner busca el
/// más cercano por ΔE en Lab para dar el nombre descriptivo ("Verde oliva").
/// Curado a mano: para un público hispanohablante es mejor una lista corta
/// con nombres reales que miles de nombres traducidos automáticamente.
nonisolated enum ColorCatalog {
    /// Familia cromática de cada entrada. El nombre descriptivo se elige
    /// solo entre familias compatibles con la categoría básica del color:
    /// a un color que se clasifica "Azul" nunca se le llama "Gris carbón"
    /// aunque quede cerca en Lab — para un usuario daltónico, que los dos
    /// textos se contradigan es peor que un nombre menos exacto.
    enum Family {
        case rojos, naranjas, amarillos, verdes, turquesas, azules, morados, rosas, marrones, neutros
    }

    struct Entry {
        let name: String
        let hex: String
        let family: Family
    }

    /// Entradas ordenadas por familias para facilitar el mantenimiento.
    static let entries: [Entry] = [
        // Rojos
        Entry(name: "Rojo carmín", hex: "#960018", family: .rojos),
        Entry(name: "Carmesí", hex: "#DC143C", family: .rojos),
        Entry(name: "Escarlata", hex: "#FF2400", family: .rojos),
        Entry(name: "Bermellón", hex: "#E34234", family: .rojos),
        Entry(name: "Rojo cereza", hex: "#DE3163", family: .rojos),
        Entry(name: "Granate", hex: "#800000", family: .rojos),
        Entry(name: "Burdeos", hex: "#800020", family: .rojos),
        Entry(name: "Rojo vino", hex: "#722F37", family: .rojos),
        Entry(name: "Rojo teja", hex: "#B55239", family: .rojos),
        Entry(name: "Ladrillo", hex: "#CB4154", family: .rojos),
        Entry(name: "Terracota", hex: "#E2725B", family: .rojos),
        Entry(name: "Coral", hex: "#FF7F50", family: .rojos),
        Entry(name: "Salmón", hex: "#FA8072", family: .rojos),
        Entry(name: "Salmón claro", hex: "#FFA07A", family: .rojos),
        Entry(name: "Rojo óxido", hex: "#B7410E", family: .rojos),
        Entry(name: "Rojo intenso", hex: "#E60026", family: .rojos),

        // Naranjas
        Entry(name: "Naranja", hex: "#FF7F00", family: .naranjas),
        Entry(name: "Mandarina", hex: "#F28500", family: .naranjas),
        Entry(name: "Calabaza", hex: "#FF7518", family: .naranjas),
        Entry(name: "Zanahoria", hex: "#ED9121", family: .naranjas),
        Entry(name: "Melocotón", hex: "#FFE5B4", family: .naranjas),
        Entry(name: "Albaricoque", hex: "#FBCEB1", family: .naranjas),
        Entry(name: "Ámbar", hex: "#FFBF00", family: .naranjas),
        Entry(name: "Cobre", hex: "#B87333", family: .naranjas),
        Entry(name: "Canela", hex: "#D2691E", family: .naranjas),
        Entry(name: "Naranja quemado", hex: "#CC5500", family: .naranjas),

        // Amarillos
        Entry(name: "Amarillo limón", hex: "#FFF700", family: .amarillos),
        Entry(name: "Amarillo canario", hex: "#FFEF00", family: .amarillos),
        Entry(name: "Mostaza", hex: "#FFDB58", family: .amarillos),
        Entry(name: "Dorado", hex: "#FFD700", family: .amarillos),
        Entry(name: "Trigo", hex: "#F5DEB3", family: .amarillos),
        Entry(name: "Vainilla", hex: "#F3E5AB", family: .amarillos),
        Entry(name: "Crema", hex: "#FFFDD0", family: .amarillos),
        Entry(name: "Ocre", hex: "#CC7722", family: .amarillos),
        Entry(name: "Arena", hex: "#C2B280", family: .amarillos),
        Entry(name: "Caqui", hex: "#C3B091", family: .amarillos),
        Entry(name: "Amarillo pastel", hex: "#FDFD96", family: .amarillos),

        // Verdes
        Entry(name: "Oliva", hex: "#808000", family: .verdes),
        Entry(name: "Verde oliva", hex: "#6B8E23", family: .verdes),
        Entry(name: "Verde caqui", hex: "#78866B", family: .verdes),
        Entry(name: "Caqui oscuro", hex: "#5B5A47", family: .verdes),
        Entry(name: "Verde militar", hex: "#4B5320", family: .verdes),
        Entry(name: "Verde lima", hex: "#BFFF00", family: .verdes),
        Entry(name: "Lima", hex: "#32CD32", family: .verdes),
        Entry(name: "Verde manzana", hex: "#8DB600", family: .verdes),
        Entry(name: "Verde hierba", hex: "#7CFC00", family: .verdes),
        Entry(name: "Verde menta", hex: "#98FF98", family: .verdes),
        Entry(name: "Verde esmeralda", hex: "#50C878", family: .verdes),
        Entry(name: "Verde jade", hex: "#00A86B", family: .verdes),
        Entry(name: "Verde bosque", hex: "#228B22", family: .verdes),
        Entry(name: "Verde pino", hex: "#01796F", family: .verdes),
        Entry(name: "Verde botella", hex: "#006A4E", family: .verdes),
        Entry(name: "Verde musgo", hex: "#8A9A5B", family: .verdes),
        Entry(name: "Verde salvia", hex: "#9CAF88", family: .verdes),
        Entry(name: "Verde mar", hex: "#2E8B57", family: .verdes),
        Entry(name: "Verde primavera", hex: "#00FF7F", family: .verdes),
        Entry(name: "Verde pastel", hex: "#77DD77", family: .verdes),
        Entry(name: "Verde puro", hex: "#00A550", family: .verdes),

        // Turquesas y cianes
        Entry(name: "Turquesa", hex: "#40E0D0", family: .turquesas),
        Entry(name: "Aguamarina", hex: "#7FFFD4", family: .turquesas),
        Entry(name: "Cian", hex: "#00FFFF", family: .turquesas),
        Entry(name: "Azul petróleo", hex: "#01636F", family: .turquesas),
        Entry(name: "Verde azulado", hex: "#008080", family: .turquesas),
        Entry(name: "Verde agua", hex: "#AFEEEE", family: .turquesas),

        // Azules
        Entry(name: "Celeste", hex: "#87CEEB", family: .azules),
        Entry(name: "Azul bebé", hex: "#89CFF0", family: .azules),
        Entry(name: "Azul acero", hex: "#4682B4", family: .azules),
        Entry(name: "Azul cobalto", hex: "#0047AB", family: .azules),
        // Marino textil (el "#000080" web es demasiado saturado y ningún
        // tejido real queda cerca de él en Lab).
        Entry(name: "Azul marino", hex: "#1F2A44", family: .azules),
        Entry(name: "Azul medianoche", hex: "#191970", family: .azules),
        Entry(name: "Azul real", hex: "#4169E1", family: .azules),
        Entry(name: "Azul eléctrico", hex: "#0892D0", family: .azules),
        Entry(name: "Índigo", hex: "#4B0082", family: .morados),
        Entry(name: "Azul zafiro", hex: "#0F52BA", family: .azules),
        Entry(name: "Azul denim", hex: "#1560BD", family: .azules),
        Entry(name: "Azul pizarra", hex: "#6A5ACD", family: .azules),
        Entry(name: "Azul aciano", hex: "#6495ED", family: .azules),
        Entry(name: "Azul pastel", hex: "#AEC6CF", family: .azules),
        Entry(name: "Azul puro", hex: "#0018F9", family: .azules),

        // Morados
        Entry(name: "Violeta", hex: "#8F00FF", family: .morados),
        Entry(name: "Púrpura", hex: "#800080", family: .morados),
        Entry(name: "Lavanda", hex: "#E6E6FA", family: .morados),
        Entry(name: "Lila", hex: "#C8A2C8", family: .morados),
        Entry(name: "Malva", hex: "#E0B0FF", family: .morados),
        Entry(name: "Orquídea", hex: "#DA70D6", family: .morados),
        Entry(name: "Ciruela", hex: "#8E4585", family: .morados),
        Entry(name: "Berenjena", hex: "#614051", family: .morados),
        Entry(name: "Amatista", hex: "#9966CC", family: .morados),
        Entry(name: "Uva", hex: "#6F2DA8", family: .morados),
        Entry(name: "Magenta", hex: "#FF00FF", family: .morados),

        // Rosas
        Entry(name: "Rosa palo", hex: "#FADADD", family: .rosas),
        Entry(name: "Rosa pastel", hex: "#FFD1DC", family: .rosas),
        Entry(name: "Rosa chicle", hex: "#FFC1CC", family: .rosas),
        Entry(name: "Fucsia", hex: "#FF00A0", family: .rosas),
        Entry(name: "Rosa fuerte", hex: "#FF69B4", family: .rosas),
        Entry(name: "Rosa salmón", hex: "#FF91A4", family: .rosas),
        Entry(name: "Rosa viejo", hex: "#C08081", family: .rosas),

        // Marrones
        Entry(name: "Chocolate", hex: "#7B3F00", family: .marrones),
        Entry(name: "Café", hex: "#6F4E37", family: .marrones),
        Entry(name: "Moca", hex: "#967969", family: .marrones),
        Entry(name: "Caoba", hex: "#C04000", family: .marrones),
        Entry(name: "Castaño", hex: "#954535", family: .marrones),
        Entry(name: "Avellana", hex: "#A67B5B", family: .marrones),
        Entry(name: "Siena", hex: "#882D17", family: .marrones),
        Entry(name: "Tierra", hex: "#E97451", family: .marrones),
        Entry(name: "Bronce", hex: "#CD7F32", family: .marrones),
        Entry(name: "Pardo", hex: "#483C32", family: .marrones),
        Entry(name: "Beige", hex: "#F5F5DC", family: .marrones),
        Entry(name: "Marfil", hex: "#FFFFF0", family: .marrones),
        Entry(name: "Hueso", hex: "#E3DAC9", family: .marrones),

        // Neutros
        Entry(name: "Blanco", hex: "#FFFFFF", family: .neutros),
        Entry(name: "Blanco roto", hex: "#FAF9F6", family: .neutros),
        Entry(name: "Blanco nieve", hex: "#FFFAFA", family: .neutros),
        Entry(name: "Gris perla", hex: "#E5E4E2", family: .neutros),
        Entry(name: "Plata", hex: "#C0C0C0", family: .neutros),
        Entry(name: "Gris claro", hex: "#D3D3D3", family: .neutros),
        Entry(name: "Gris", hex: "#808080", family: .neutros),
        Entry(name: "Gris pizarra", hex: "#708090", family: .neutros),
        Entry(name: "Gris carbón", hex: "#36454F", family: .neutros),
        Entry(name: "Grafito", hex: "#383838", family: .neutros),
        Entry(name: "Negro", hex: "#000000", family: .neutros),
    ]

    /// Entradas con su Lab precalculado (una sola vez).
    static let resolved: [(name: String, family: Family, lab: (l: Double, a: Double, b: Double))] =
        entries.map { entry in
            (entry.name, entry.family, LinearRGB(hex: entry.hex).lab)
        }

    /// Familias que pueden dar nombre a cada categoría básica; nil = todas.
    private static func allowedFamilies(forBasic basic: String) -> Set<Family>? {
        switch basic {
        case String(localized: "Rojo"): [.rojos]
        case String(localized: "Naranja"): [.naranjas, .rojos]
        case String(localized: "Amarillo"): [.amarillos]
        case String(localized: "Beige"): [.amarillos, .marrones]
        case String(localized: "Verde"): [.verdes]
        case String(localized: "Turquesa"): [.turquesas]
        case String(localized: "Azul"): [.azules]
        case String(localized: "Morado"): [.morados]
        case String(localized: "Rosa"): [.rosas]
        case String(localized: "Marrón"): [.marrones, .naranjas]
        case String(localized: "Gris"), String(localized: "Negro"), String(localized: "Blanco"): [.neutros]
        default: nil
        }
    }

    /// Nombre descriptivo: el color más cercano por ΔE dentro de las
    /// familias compatibles con la categoría básica, para que ambos textos
    /// cuenten siempre la misma historia.
    static func closestName(to color: LinearRGB) -> String {
        let allowed = allowedFamilies(forBasic: ColorNamer.basicName(for: color))
        let target = color.lab
        var bestName = entries[0].name
        var bestDistance = Double.infinity
        for entry in resolved {
            if let allowed, !allowed.contains(entry.family) { continue }
            let dl = target.l - entry.lab.l
            let da = target.a - entry.lab.a
            let db = target.b - entry.lab.b
            let distance = dl * dl + da * da + db * db
            if distance < bestDistance {
                bestDistance = distance
                bestName = entry.name
            }
        }
        return bestName
    }
}
