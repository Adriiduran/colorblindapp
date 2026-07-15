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
        Entry(name: String(localized: "Rojo carmín"), hex: "#960018", family: .rojos),
        Entry(name: String(localized: "Carmesí"), hex: "#DC143C", family: .rojos),
        Entry(name: String(localized: "Escarlata"), hex: "#FF2400", family: .rojos),
        Entry(name: String(localized: "Bermellón"), hex: "#E34234", family: .rojos),
        Entry(name: String(localized: "Rojo cereza"), hex: "#DE3163", family: .rojos),
        Entry(name: String(localized: "Granate"), hex: "#800000", family: .rojos),
        Entry(name: String(localized: "Burdeos"), hex: "#800020", family: .rojos),
        Entry(name: String(localized: "Rojo vino"), hex: "#722F37", family: .rojos),
        Entry(name: String(localized: "Rojo teja"), hex: "#B55239", family: .rojos),
        Entry(name: String(localized: "Ladrillo"), hex: "#CB4154", family: .rojos),
        Entry(name: String(localized: "Terracota"), hex: "#E2725B", family: .rojos),
        Entry(name: String(localized: "Coral"), hex: "#FF7F50", family: .rojos),
        Entry(name: String(localized: "Salmón"), hex: "#FA8072", family: .rojos),
        Entry(name: String(localized: "Salmón claro"), hex: "#FFA07A", family: .rojos),
        Entry(name: String(localized: "Rojo óxido"), hex: "#B7410E", family: .rojos),
        Entry(name: String(localized: "Rojo intenso"), hex: "#E60026", family: .rojos),

        // Naranjas
        Entry(name: String(localized: "Naranja"), hex: "#FF7F00", family: .naranjas),
        Entry(name: String(localized: "Mandarina"), hex: "#F28500", family: .naranjas),
        Entry(name: String(localized: "Calabaza"), hex: "#FF7518", family: .naranjas),
        Entry(name: String(localized: "Zanahoria"), hex: "#ED9121", family: .naranjas),
        Entry(name: String(localized: "Melocotón"), hex: "#FFE5B4", family: .naranjas),
        Entry(name: String(localized: "Albaricoque"), hex: "#FBCEB1", family: .naranjas),
        Entry(name: String(localized: "Ámbar"), hex: "#FFBF00", family: .naranjas),
        Entry(name: String(localized: "Cobre"), hex: "#B87333", family: .naranjas),
        Entry(name: String(localized: "Canela"), hex: "#D2691E", family: .naranjas),
        Entry(name: String(localized: "Naranja quemado"), hex: "#CC5500", family: .naranjas),

        // Amarillos
        Entry(name: String(localized: "Amarillo limón"), hex: "#FFF700", family: .amarillos),
        Entry(name: String(localized: "Amarillo canario"), hex: "#FFEF00", family: .amarillos),
        Entry(name: String(localized: "Mostaza"), hex: "#FFDB58", family: .amarillos),
        Entry(name: String(localized: "Dorado"), hex: "#FFD700", family: .amarillos),
        Entry(name: String(localized: "Trigo"), hex: "#F5DEB3", family: .amarillos),
        Entry(name: String(localized: "Vainilla"), hex: "#F3E5AB", family: .amarillos),
        Entry(name: String(localized: "Crema"), hex: "#FFFDD0", family: .amarillos),
        Entry(name: String(localized: "Ocre"), hex: "#CC7722", family: .amarillos),
        Entry(name: String(localized: "Arena"), hex: "#C2B280", family: .amarillos),
        Entry(name: String(localized: "Caqui"), hex: "#C3B091", family: .amarillos),
        Entry(name: String(localized: "Amarillo pastel"), hex: "#FDFD96", family: .amarillos),

        // Verdes
        Entry(name: String(localized: "Oliva"), hex: "#808000", family: .verdes),
        Entry(name: String(localized: "Verde oliva"), hex: "#6B8E23", family: .verdes),
        Entry(name: String(localized: "Verde caqui"), hex: "#78866B", family: .verdes),
        Entry(name: String(localized: "Caqui oscuro"), hex: "#5B5A47", family: .verdes),
        Entry(name: String(localized: "Verde militar"), hex: "#4B5320", family: .verdes),
        Entry(name: String(localized: "Verde lima"), hex: "#BFFF00", family: .verdes),
        Entry(name: String(localized: "Lima"), hex: "#32CD32", family: .verdes),
        Entry(name: String(localized: "Verde manzana"), hex: "#8DB600", family: .verdes),
        Entry(name: String(localized: "Verde hierba"), hex: "#7CFC00", family: .verdes),
        Entry(name: String(localized: "Verde menta"), hex: "#98FF98", family: .verdes),
        Entry(name: String(localized: "Verde esmeralda"), hex: "#50C878", family: .verdes),
        Entry(name: String(localized: "Verde jade"), hex: "#00A86B", family: .verdes),
        Entry(name: String(localized: "Verde bosque"), hex: "#228B22", family: .verdes),
        Entry(name: String(localized: "Verde pino"), hex: "#01796F", family: .verdes),
        Entry(name: String(localized: "Verde botella"), hex: "#006A4E", family: .verdes),
        Entry(name: String(localized: "Verde musgo"), hex: "#8A9A5B", family: .verdes),
        Entry(name: String(localized: "Verde salvia"), hex: "#9CAF88", family: .verdes),
        Entry(name: String(localized: "Verde mar"), hex: "#2E8B57", family: .verdes),
        Entry(name: String(localized: "Verde primavera"), hex: "#00FF7F", family: .verdes),
        Entry(name: String(localized: "Verde pastel"), hex: "#77DD77", family: .verdes),
        Entry(name: String(localized: "Verde puro"), hex: "#00A550", family: .verdes),

        // Turquesas y cianes
        Entry(name: String(localized: "Turquesa"), hex: "#40E0D0", family: .turquesas),
        Entry(name: String(localized: "Aguamarina"), hex: "#7FFFD4", family: .turquesas),
        Entry(name: String(localized: "Cian"), hex: "#00FFFF", family: .turquesas),
        Entry(name: String(localized: "Azul petróleo"), hex: "#01636F", family: .turquesas),
        Entry(name: String(localized: "Verde azulado"), hex: "#008080", family: .turquesas),
        Entry(name: String(localized: "Verde agua"), hex: "#AFEEEE", family: .turquesas),

        // Azules
        Entry(name: String(localized: "Celeste"), hex: "#87CEEB", family: .azules),
        Entry(name: String(localized: "Azul bebé"), hex: "#89CFF0", family: .azules),
        Entry(name: String(localized: "Azul acero"), hex: "#4682B4", family: .azules),
        Entry(name: String(localized: "Azul cobalto"), hex: "#0047AB", family: .azules),
        // Marino textil (el "#000080" web es demasiado saturado y ningún
        // tejido real queda cerca de él en Lab).
        Entry(name: String(localized: "Azul marino"), hex: "#1F2A44", family: .azules),
        Entry(name: String(localized: "Azul medianoche"), hex: "#191970", family: .azules),
        Entry(name: String(localized: "Azul real"), hex: "#4169E1", family: .azules),
        Entry(name: String(localized: "Azul eléctrico"), hex: "#0892D0", family: .azules),
        Entry(name: String(localized: "Índigo"), hex: "#4B0082", family: .morados),
        Entry(name: String(localized: "Azul zafiro"), hex: "#0F52BA", family: .azules),
        Entry(name: String(localized: "Azul denim"), hex: "#1560BD", family: .azules),
        Entry(name: String(localized: "Azul pizarra"), hex: "#6A5ACD", family: .azules),
        Entry(name: String(localized: "Azul aciano"), hex: "#6495ED", family: .azules),
        Entry(name: String(localized: "Azul pastel"), hex: "#AEC6CF", family: .azules),
        Entry(name: String(localized: "Azul puro"), hex: "#0018F9", family: .azules),

        // Morados
        Entry(name: String(localized: "Violeta"), hex: "#8F00FF", family: .morados),
        Entry(name: String(localized: "Púrpura"), hex: "#800080", family: .morados),
        Entry(name: String(localized: "Lavanda"), hex: "#E6E6FA", family: .morados),
        Entry(name: String(localized: "Lila"), hex: "#C8A2C8", family: .morados),
        Entry(name: String(localized: "Malva"), hex: "#E0B0FF", family: .morados),
        Entry(name: String(localized: "Orquídea"), hex: "#DA70D6", family: .morados),
        Entry(name: String(localized: "Ciruela"), hex: "#8E4585", family: .morados),
        Entry(name: String(localized: "Berenjena"), hex: "#614051", family: .morados),
        Entry(name: String(localized: "Amatista"), hex: "#9966CC", family: .morados),
        Entry(name: String(localized: "Uva"), hex: "#6F2DA8", family: .morados),
        Entry(name: String(localized: "Magenta"), hex: "#FF00FF", family: .morados),

        // Rosas
        Entry(name: String(localized: "Rosa palo"), hex: "#FADADD", family: .rosas),
        Entry(name: String(localized: "Rosa pastel"), hex: "#FFD1DC", family: .rosas),
        Entry(name: String(localized: "Rosa chicle"), hex: "#FFC1CC", family: .rosas),
        Entry(name: String(localized: "Fucsia"), hex: "#FF00A0", family: .rosas),
        Entry(name: String(localized: "Rosa fuerte"), hex: "#FF69B4", family: .rosas),
        Entry(name: String(localized: "Rosa salmón"), hex: "#FF91A4", family: .rosas),
        Entry(name: String(localized: "Rosa viejo"), hex: "#C08081", family: .rosas),

        // Marrones
        Entry(name: String(localized: "Chocolate"), hex: "#7B3F00", family: .marrones),
        Entry(name: String(localized: "Café"), hex: "#6F4E37", family: .marrones),
        Entry(name: String(localized: "Moca"), hex: "#967969", family: .marrones),
        Entry(name: String(localized: "Caoba"), hex: "#C04000", family: .marrones),
        Entry(name: String(localized: "Castaño"), hex: "#954535", family: .marrones),
        Entry(name: String(localized: "Avellana"), hex: "#A67B5B", family: .marrones),
        Entry(name: String(localized: "Siena"), hex: "#882D17", family: .marrones),
        Entry(name: String(localized: "Tierra"), hex: "#E97451", family: .marrones),
        Entry(name: String(localized: "Bronce"), hex: "#CD7F32", family: .marrones),
        Entry(name: String(localized: "Pardo"), hex: "#483C32", family: .marrones),
        Entry(name: String(localized: "Beige"), hex: "#F5F5DC", family: .marrones),
        Entry(name: String(localized: "Marfil"), hex: "#FFFFF0", family: .marrones),
        Entry(name: String(localized: "Hueso"), hex: "#E3DAC9", family: .marrones),

        // Neutros
        Entry(name: String(localized: "Blanco"), hex: "#FFFFFF", family: .neutros),
        Entry(name: String(localized: "Blanco roto"), hex: "#FAF9F6", family: .neutros),
        Entry(name: String(localized: "Blanco nieve"), hex: "#FFFAFA", family: .neutros),
        Entry(name: String(localized: "Gris perla"), hex: "#E5E4E2", family: .neutros),
        Entry(name: String(localized: "Plata"), hex: "#C0C0C0", family: .neutros),
        Entry(name: String(localized: "Gris claro"), hex: "#D3D3D3", family: .neutros),
        Entry(name: String(localized: "Gris"), hex: "#808080", family: .neutros),
        Entry(name: String(localized: "Gris pizarra"), hex: "#708090", family: .neutros),
        Entry(name: String(localized: "Gris carbón"), hex: "#36454F", family: .neutros),
        Entry(name: String(localized: "Grafito"), hex: "#383838", family: .neutros),
        Entry(name: String(localized: "Negro"), hex: "#000000", family: .neutros),
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
