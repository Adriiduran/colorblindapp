//
//  OutfitEngine.swift
//  colorblindapp
//

import Foundation

/// Hueco que ocupa una prenda dentro de un outfit. El rawValue define el
/// orden de presentación (de arriba abajo).
enum OutfitSlot: Int, Comparable {
    case top = 0
    case fullBody = 1
    case bottom = 2
    case shoes = 3
    case outer = 4

    static func < (lhs: OutfitSlot, rhs: OutfitSlot) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension GarmentCategory {
    /// Hueco del outfit que cubre esta categoría; nil si no participa en el
    /// generador (accesorios y "otro").
    var outfitSlot: OutfitSlot? {
        switch self {
        case .camiseta, .camisa, .jersey: .top
        case .vestido: .fullBody
        case .pantalon, .falda: .bottom
        case .zapatos: .shoes
        case .chaqueta: .outer
        case .accesorio, .otro: nil
        }
    }

    /// "la camiseta", "los zapatos"… para construir explicaciones legibles.
    var withArticle: String {
        switch self {
        case .camiseta: String(localized: "la camiseta")
        case .camisa: String(localized: "la camisa")
        case .jersey: String(localized: "el jersey")
        case .chaqueta: String(localized: "la chaqueta")
        case .pantalon: String(localized: "el pantalón")
        case .falda: String(localized: "la falda")
        case .vestido: String(localized: "el vestido")
        case .zapatos: String(localized: "los zapatos")
        case .accesorio: String(localized: "el accesorio")
        case .otro: String(localized: "la prenda")
        }
    }
}

/// Motor de combinación de outfits: compone conjuntos (arriba + abajo +
/// calzado + capa opcional, o vestido) y los puntúa con reglas de
/// colorimetría sobre el círculo cromático — neutros, monocromático,
/// análogos, complementarios, tríadas y choques conocidos. Cada propuesta
/// lleva una explicación en texto: para un usuario daltónico la explicación
/// vale tanto como la propuesta.
enum OutfitEngine {
    struct Proposal: Identifiable {
        let id = UUID()
        /// Prendas en orden de presentación (arriba → abajo → calzado → capa).
        let garments: [Garment]
        /// Puntuación 0-100.
        let score: Double
        let explanation: String
    }

    // MARK: - Generación

    /// Compone las mejores combinaciones del armario. Si hay prenda ancla,
    /// todas las propuestas la incluyen. Prioriza variedad: no repite el
    /// mismo par arriba+abajo salvo que falten propuestas.
    static func proposals(from wardrobe: [Garment], anchor: Garment? = nil, limit: Int = 5) -> [Proposal] {
        let tops = wardrobe.filter { $0.category.outfitSlot == .top }
        let bottoms = wardrobe.filter { $0.category.outfitSlot == .bottom }
        let fullBodies = wardrobe.filter { $0.category.outfitSlot == .fullBody }
        let shoes = wardrobe.filter { $0.category.outfitSlot == .shoes }
        let outers = wardrobe.filter { $0.category.outfitSlot == .outer }

        var bases: [[Garment]] = fullBodies.map { [$0] }
        for top in tops {
            for bottom in bottoms {
                bases.append([top, bottom])
            }
        }

        let shoeOptions: [Garment?] = shoes.isEmpty ? [nil] : shoes.map(Optional.some)
        let outerOptions: [Garment?] = [nil] + outers.map(Optional.some)

        var candidates: [(baseKey: [ObjectIdentifier], proposal: Proposal)] = []
        for base in bases {
            let baseKey = base.map(ObjectIdentifier.init)
            for shoe in shoeOptions {
                for outer in outerOptions {
                    let garments = base + [shoe, outer].compactMap(\.self)
                    if let anchor, !garments.contains(where: { $0 === anchor }) { continue }
                    candidates.append((baseKey, evaluate(garments)))
                }
            }
        }
        candidates.sort { $0.proposal.score > $1.proposal.score }

        // Primero la mejor variante de cada base arriba+abajo; solo se
        // repite base si faltan propuestas para llegar al límite.
        var chosen: [Proposal] = []
        var seenBases: Set<[ObjectIdentifier]> = []
        for candidate in candidates where chosen.count < limit {
            if seenBases.insert(candidate.baseKey).inserted {
                chosen.append(candidate.proposal)
            }
        }
        if chosen.count < limit {
            let chosenIDs = Set(chosen.map(\.id))
            for candidate in candidates where chosen.count < limit {
                if !chosenIDs.contains(candidate.proposal.id) {
                    chosen.append(candidate.proposal)
                }
            }
        }
        return chosen.sorted { $0.score > $1.score }
    }

    // MARK: - Neutros

    /// Un color de armario cuenta como neutro si es Blanco/Negro/Gris/Beige,
    /// o azul marino/denim (marino oscuro o azul apagado). Se usa tanto para
    /// puntuar armonía como para la auditoría de armario (`WardrobeAudit`).
    static func isNeutral(basicName: String, saturation: Double, lightness: Double) -> Bool {
        let neutralNames = [
            String(localized: "Blanco"), String(localized: "Negro"),
            String(localized: "Gris"), String(localized: "Beige"),
        ]
        let isMutedBlue = basicName == String(localized: "Azul")
            && (lightness < 0.3 || saturation < 0.45)
        return neutralNames.contains(basicName) || isMutedBlue
    }

    // MARK: - Puntuación

    /// Puntúa un conjunto concreto y redacta su explicación.
    static func evaluate(_ garments: [Garment]) -> Proposal {
        var features: [Feature] = []
        for garment in garments {
            features.append(Feature(garment))
        }

        var verdicts: [(weight: Double, verdict: PairVerdict)] = []
        for i in features.indices {
            for j in features.indices.dropFirst(i + 1) {
                let weight = pairWeight(features[i].slot, features[j].slot)
                verdicts.append((weight, assess(features[i], features[j])))
            }
        }

        // Un vestido sin más prendas es un outfit válido por sí solo.
        guard !verdicts.isEmpty else {
            return Proposal(
                garments: garments,
                score: 70,
                explanation: String(localized: "Un vestido funciona por sí solo. Añade calzado a tu armario para propuestas más completas.")
            )
        }

        let totalWeight = verdicts.reduce(0) { $0 + $1.weight }
        let score = verdicts.reduce(0) { $0 + $1.weight * $1.verdict.score } / totalWeight
        return Proposal(garments: garments, score: score, explanation: explanation(score: score, verdicts: verdicts))
    }

    /// Cuánto pesa cada par en la nota final: lo que más se ve junto manda.
    private static func pairWeight(_ a: OutfitSlot, _ b: OutfitSlot) -> Double {
        let pair = Set([a, b])
        if pair == [.top, .bottom] { return 3 }
        if pair == [.outer, .top] || pair == [.outer, .fullBody] { return 2 }
        return 1
    }

    /// Rasgos de color de una prenda ya precalculados para puntuar.
    private struct Feature {
        let slot: OutfitSlot
        let hue: Double
        let saturation: Double
        let lightness: Double
        let isNeutral: Bool
        let basicName: String
        /// "la camiseta verde oliva" — para las explicaciones.
        let label: String
        /// "verde oliva"
        let colorLabel: String

        init(_ garment: Garment) {
            slot = garment.category.outfitSlot ?? .top
            (hue, saturation, lightness) = garment.dominantColor.hsl
            basicName = garment.basicName
            isNeutral = OutfitEngine.isNeutral(basicName: basicName, saturation: saturation, lightness: lightness)
            colorLabel = garment.descriptiveName.lowercased()
            label = "\(garment.category.withArticle) \(colorLabel)"
        }
    }

    /// Tipo de razón de armonía; se usa para no repetir la misma plantilla
    /// dos veces en una explicación ("X es un neutro…; además, Y es un
    /// neutro…" se queda en una sola mención).
    private enum HarmonyKind {
        case neutralPair, neutralSingle, mono, monoFlat, analogous, complementary, triad, unclear
    }

    private struct PairVerdict {
        var score: Double
        var kind: HarmonyKind
        var phrase: String
        var warning: String?
    }

    /// Reglas de armonía entre dos prendas: nota 0-100 más la frase que la
    /// justifica y, si aplica, un aviso.
    private static func assess(_ a: Feature, _ b: Feature) -> PairVerdict {
        var verdict: PairVerdict

        if a.isNeutral && b.isNeutral {
            verdict = PairVerdict(
                score: 80,
                kind: .neutralPair,
                phrase: String(localized: "\(a.label) y \(b.label) van en colores neutros, una base que nunca falla")
            )
        } else if a.isNeutral || b.isNeutral {
            let neutral = a.isNeutral ? a : b
            verdict = PairVerdict(
                score: 85,
                kind: .neutralSingle,
                phrase: String(localized: "\(neutral.label) es un neutro que combina con casi todo")
            )
        } else {
            let rawDelta = abs(a.hue - b.hue)
            let hueDelta = min(rawDelta, 360 - rawDelta)
            let lightnessDelta = abs(a.lightness - b.lightness)
            switch hueDelta {
            case ..<18 where lightnessDelta >= 0.15:
                verdict = PairVerdict(
                    score: 80,
                    kind: .mono,
                    phrase: String(localized: "\(a.label) y \(b.label) comparten tono en distinta intensidad: un monocromático elegante")
                )
            case ..<18:
                verdict = PairVerdict(
                    score: 52,
                    kind: .monoFlat,
                    phrase: String(localized: "\(a.label) y \(b.label) son casi del mismo color y pueden fundirse entre sí")
                )
            case ..<45:
                verdict = PairVerdict(
                    score: 75,
                    kind: .analogous,
                    phrase: String(localized: "el \(a.colorLabel) y el \(b.colorLabel) son tonos vecinos en el círculo cromático y armonizan con naturalidad")
                )
            case 150...:
                verdict = PairVerdict(
                    score: 70,
                    kind: .complementary,
                    phrase: String(localized: "el \(a.colorLabel) y el \(b.colorLabel) se oponen en el círculo cromático: un contraste llamativo que da vida al conjunto")
                )
            case 100...:
                verdict = PairVerdict(
                    score: 64,
                    kind: .triad,
                    phrase: String(localized: "el \(a.colorLabel) y el \(b.colorLabel) guardan un contraste a tres bandas (tríada), vivo sin estridencias")
                )
            default:
                verdict = PairVerdict(
                    score: 45,
                    kind: .unclear,
                    phrase: String(localized: "el \(a.colorLabel) y el \(b.colorLabel) no siguen una armonía clara entre sí")
                )
            }

            if a.saturation > 0.55 && b.saturation > 0.55 && hueDelta > 25 {
                verdict.score -= 18
                verdict.warning = String(localized: "dos colores muy intensos compiten por la atención")
            }
        }

        let names = Set([a.basicName, b.basicName])
        if names == [String(localized: "Rojo"), String(localized: "Rosa")] {
            verdict.score -= 20
            verdict.warning = String(localized: "el rojo y el rosa suelen chocar entre sí")
        } else if names == [String(localized: "Marrón"), String(localized: "Negro")] {
            verdict.score -= 12
            verdict.warning = String(localized: "marrón con negro es una mezcla delicada")
        }

        verdict.score = min(max(verdict.score, 5), 98)
        return verdict
    }

    /// Redacta la explicación del outfit a partir de los pares: las dos
    /// razones de más peso, más los avisos si los hay.
    private static func explanation(score: Double, verdicts: [(weight: Double, verdict: PairVerdict)]) -> String {
        let ordered = verdicts.sorted { ($0.weight, $0.verdict.score) > ($1.weight, $1.verdict.score) }

        var phrases: [String] = []
        var seenKinds: [HarmonyKind] = []
        var warnings: [String] = []
        for item in ordered {
            if !seenKinds.contains(item.verdict.kind) {
                seenKinds.append(item.verdict.kind)
                phrases.append(item.verdict.phrase)
            }
            if let warning = item.verdict.warning, !warnings.contains(warning) {
                warnings.append(warning)
            }
        }

        let reasons = phrases.prefix(2).joined(separator: "; además, ")
        var text = score >= 60
            ? String(localized: "Combina porque \(reasons).")
            : String(localized: "Propuesta con reservas: \(reasons).")
        if !warnings.isEmpty {
            let joinedWarnings = warnings.joined(separator: String(localized: " y ", comment: "Separador entre avisos de un outfit, p. ej. \"aviso 1 y aviso 2\""))
            text += " " + String(localized: "Ojo: \(joinedWarnings).")
        }
        return text
    }
}
