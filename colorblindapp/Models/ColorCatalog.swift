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
    struct Entry {
        let name: String
        let hex: String
    }

    /// Entradas ordenadas por familias para facilitar el mantenimiento.
    static let entries: [Entry] = [
        // Rojos
        Entry(name: "Rojo carmín", hex: "#960018"),
        Entry(name: "Carmesí", hex: "#DC143C"),
        Entry(name: "Escarlata", hex: "#FF2400"),
        Entry(name: "Bermellón", hex: "#E34234"),
        Entry(name: "Rojo cereza", hex: "#DE3163"),
        Entry(name: "Granate", hex: "#800000"),
        Entry(name: "Burdeos", hex: "#800020"),
        Entry(name: "Rojo vino", hex: "#722F37"),
        Entry(name: "Rojo teja", hex: "#B55239"),
        Entry(name: "Ladrillo", hex: "#CB4154"),
        Entry(name: "Terracota", hex: "#E2725B"),
        Entry(name: "Coral", hex: "#FF7F50"),
        Entry(name: "Salmón", hex: "#FA8072"),
        Entry(name: "Salmón claro", hex: "#FFA07A"),
        Entry(name: "Rojo óxido", hex: "#B7410E"),
        Entry(name: "Rojo intenso", hex: "#E60026"),

        // Naranjas
        Entry(name: "Naranja", hex: "#FF7F00"),
        Entry(name: "Mandarina", hex: "#F28500"),
        Entry(name: "Calabaza", hex: "#FF7518"),
        Entry(name: "Zanahoria", hex: "#ED9121"),
        Entry(name: "Melocotón", hex: "#FFE5B4"),
        Entry(name: "Albaricoque", hex: "#FBCEB1"),
        Entry(name: "Ámbar", hex: "#FFBF00"),
        Entry(name: "Cobre", hex: "#B87333"),
        Entry(name: "Canela", hex: "#D2691E"),
        Entry(name: "Naranja quemado", hex: "#CC5500"),

        // Amarillos
        Entry(name: "Amarillo limón", hex: "#FFF700"),
        Entry(name: "Amarillo canario", hex: "#FFEF00"),
        Entry(name: "Mostaza", hex: "#FFDB58"),
        Entry(name: "Dorado", hex: "#FFD700"),
        Entry(name: "Trigo", hex: "#F5DEB3"),
        Entry(name: "Vainilla", hex: "#F3E5AB"),
        Entry(name: "Crema", hex: "#FFFDD0"),
        Entry(name: "Ocre", hex: "#CC7722"),
        Entry(name: "Arena", hex: "#C2B280"),
        Entry(name: "Caqui", hex: "#C3B091"),
        Entry(name: "Amarillo pastel", hex: "#FDFD96"),

        // Verdes
        Entry(name: "Oliva", hex: "#808000"),
        Entry(name: "Verde oliva", hex: "#6B8E23"),
        Entry(name: "Verde caqui", hex: "#78866B"),
        Entry(name: "Verde lima", hex: "#BFFF00"),
        Entry(name: "Lima", hex: "#32CD32"),
        Entry(name: "Verde manzana", hex: "#8DB600"),
        Entry(name: "Verde hierba", hex: "#7CFC00"),
        Entry(name: "Verde menta", hex: "#98FF98"),
        Entry(name: "Verde esmeralda", hex: "#50C878"),
        Entry(name: "Verde jade", hex: "#00A86B"),
        Entry(name: "Verde bosque", hex: "#228B22"),
        Entry(name: "Verde pino", hex: "#01796F"),
        Entry(name: "Verde botella", hex: "#006A4E"),
        Entry(name: "Verde musgo", hex: "#8A9A5B"),
        Entry(name: "Verde salvia", hex: "#9CAF88"),
        Entry(name: "Verde mar", hex: "#2E8B57"),
        Entry(name: "Verde primavera", hex: "#00FF7F"),
        Entry(name: "Verde pastel", hex: "#77DD77"),
        Entry(name: "Verde puro", hex: "#00A550"),

        // Turquesas y cianes
        Entry(name: "Turquesa", hex: "#40E0D0"),
        Entry(name: "Aguamarina", hex: "#7FFFD4"),
        Entry(name: "Cian", hex: "#00FFFF"),
        Entry(name: "Azul petróleo", hex: "#01636F"),
        Entry(name: "Verde azulado", hex: "#008080"),
        Entry(name: "Verde agua", hex: "#AFEEEE"),

        // Azules
        Entry(name: "Azul celeste", hex: "#87CEEB"),
        Entry(name: "Azul bebé", hex: "#89CFF0"),
        Entry(name: "Azul acero", hex: "#4682B4"),
        Entry(name: "Azul cobalto", hex: "#0047AB"),
        Entry(name: "Azul marino", hex: "#000080"),
        Entry(name: "Azul medianoche", hex: "#191970"),
        Entry(name: "Azul real", hex: "#4169E1"),
        Entry(name: "Azul eléctrico", hex: "#0892D0"),
        Entry(name: "Índigo", hex: "#4B0082"),
        Entry(name: "Azul zafiro", hex: "#0F52BA"),
        Entry(name: "Azul denim", hex: "#1560BD"),
        Entry(name: "Azul pizarra", hex: "#6A5ACD"),
        Entry(name: "Azul aciano", hex: "#6495ED"),
        Entry(name: "Azul pastel", hex: "#AEC6CF"),
        Entry(name: "Azul puro", hex: "#0018F9"),

        // Morados
        Entry(name: "Violeta", hex: "#8F00FF"),
        Entry(name: "Púrpura", hex: "#800080"),
        Entry(name: "Lavanda", hex: "#E6E6FA"),
        Entry(name: "Lila", hex: "#C8A2C8"),
        Entry(name: "Malva", hex: "#E0B0FF"),
        Entry(name: "Orquídea", hex: "#DA70D6"),
        Entry(name: "Ciruela", hex: "#8E4585"),
        Entry(name: "Berenjena", hex: "#614051"),
        Entry(name: "Amatista", hex: "#9966CC"),
        Entry(name: "Uva", hex: "#6F2DA8"),
        Entry(name: "Magenta", hex: "#FF00FF"),

        // Rosas
        Entry(name: "Rosa palo", hex: "#FADADD"),
        Entry(name: "Rosa pastel", hex: "#FFD1DC"),
        Entry(name: "Rosa chicle", hex: "#FFC1CC"),
        Entry(name: "Fucsia", hex: "#FF00A0"),
        Entry(name: "Rosa fuerte", hex: "#FF69B4"),
        Entry(name: "Rosa salmón", hex: "#FF91A4"),
        Entry(name: "Rosa viejo", hex: "#C08081"),

        // Marrones
        Entry(name: "Chocolate", hex: "#7B3F00"),
        Entry(name: "Café", hex: "#6F4E37"),
        Entry(name: "Moca", hex: "#967969"),
        Entry(name: "Caoba", hex: "#C04000"),
        Entry(name: "Castaño", hex: "#954535"),
        Entry(name: "Avellana", hex: "#A67B5B"),
        Entry(name: "Siena", hex: "#882D17"),
        Entry(name: "Tierra", hex: "#E97451"),
        Entry(name: "Bronce", hex: "#CD7F32"),
        Entry(name: "Pardo", hex: "#483C32"),
        Entry(name: "Beige", hex: "#F5F5DC"),
        Entry(name: "Marfil", hex: "#FFFFF0"),
        Entry(name: "Hueso", hex: "#E3DAC9"),

        // Neutros
        Entry(name: "Blanco", hex: "#FFFFFF"),
        Entry(name: "Blanco roto", hex: "#FAF9F6"),
        Entry(name: "Blanco nieve", hex: "#FFFAFA"),
        Entry(name: "Gris perla", hex: "#E5E4E2"),
        Entry(name: "Plata", hex: "#C0C0C0"),
        Entry(name: "Gris claro", hex: "#D3D3D3"),
        Entry(name: "Gris", hex: "#808080"),
        Entry(name: "Gris pizarra", hex: "#708090"),
        Entry(name: "Gris carbón", hex: "#36454F"),
        Entry(name: "Grafito", hex: "#383838"),
        Entry(name: "Negro", hex: "#000000"),
    ]

    /// Entradas con su Lab precalculado (una sola vez).
    static let resolved: [(name: String, color: LinearRGB, lab: (l: Double, a: Double, b: Double))] =
        entries.map { entry in
            let color = LinearRGB(hex: entry.hex)
            return (entry.name, color, color.lab)
        }

    /// Nombre descriptivo: el color del catálogo más cercano por ΔE.
    static func closestName(to color: LinearRGB) -> String {
        let target = color.lab
        var bestName = entries[0].name
        var bestDistance = Double.infinity
        for entry in resolved {
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
