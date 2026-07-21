//
//  WardrobeAudit.swift
//  colorblindapp
//

import Foundation
import SwiftUI

/// Motor puro de la auditoría del armario: a partir de las prendas guardadas
/// y el daltonismo del usuario calcula distribución de color, % de prendas
/// mutuamente confundibles, huecos y una lista de colores recomendados.
/// Todo síncrono y determinista, sin dependencias de vista (mismo espíritu
/// que `OutfitEngine`).
nonisolated enum WardrobeAudit {
    // MARK: - Umbrales

    /// ΔE2000 mínimo entre dos colores reales para considerarlos "distintos
    /// a la vista normal" — si ya están más cerca que esto, se confunden
    /// para cualquiera y no es un problema achacable al daltonismo.
    private static let distinctRealThreshold: Double = 25
    /// ΔE2000 máximo entre dos colores simulados con el daltonismo del
    /// usuario para considerarlos "iguales" bajo esa visión.
    private static let confusableSimulatedThreshold: Double = 12

    // MARK: - Modelos del informe

    struct ColorSlice: Identifiable {
        var id: String { name }
        let name: String
        let count: Int
        let share: Double
        let color: Color
    }

    struct ConfusableCluster: Identifiable {
        let id = UUID()
        let garments: [Garment]
    }

    enum GapKind {
        case noNeutrals
        case missingSlot(OutfitSlot)
        case overConcentration(basicName: String, share: Double)
    }

    struct Gap: Identifiable {
        let id = UUID()
        let kind: GapKind
        let message: String
    }

    struct ColorRecommendation: Identifiable {
        let id = UUID()
        let name: String
        let color: Color
        let reason: String
        /// 1 = prioridad máxima.
        let priority: Int
    }

    struct Report {
        let totalCount: Int
        let distribution: [ColorSlice]
        let confusablePercentage: Double
        let confusableClusters: [ConfusableCluster]
        let gaps: [Gap]
        let recommendations: [ColorRecommendation]
    }

    // MARK: - Entrada principal

    static func report(for garments: [Garment], visionType: ColorVisionType) -> Report {
        let distribution = distribution(for: garments)
        let (confusablePercentage, confusableClusters) = confusables(in: garments, visionType: visionType)
        let gaps = gaps(for: garments, distribution: distribution)
        let recommendations = recommendations(
            for: garments,
            distribution: distribution,
            gaps: gaps,
            visionType: visionType
        )
        return Report(
            totalCount: garments.count,
            distribution: distribution,
            confusablePercentage: confusablePercentage,
            confusableClusters: confusableClusters,
            gaps: gaps,
            recommendations: recommendations
        )
    }

    // MARK: - Distribución

    private static func distribution(for garments: [Garment]) -> [ColorSlice] {
        guard !garments.isEmpty else { return [] }
        var counts: [String: Int] = [:]
        var colors: [String: Color] = [:]
        for garment in garments {
            let name = garment.basicName
            counts[name, default: 0] += 1
            if colors[name] == nil {
                colors[name] = garment.dominantColor.color
            }
        }
        let total = Double(garments.count)
        return counts
            .map { name, count in
                ColorSlice(name: name, count: count, share: Double(count) / total, color: colors[name] ?? .gray)
            }
            .sorted { $0.count != $1.count ? $0.count > $1.count : $0.name < $1.name }
    }

    // MARK: - Confundibles

    /// Empareja toda la ropa contra sí misma y agrupa en componentes conexos
    /// los pares que un usuario con `visionType` no distinguiría, aunque a
    /// simple vista sean colores distintos.
    private static func confusables(
        in garments: [Garment],
        visionType: ColorVisionType
    ) -> (percentage: Double, clusters: [ConfusableCluster]) {
        guard visionType != .normal, garments.count >= 2 else { return (0, []) }

        var adjacency: [Int: Set<Int>] = [:]
        for i in garments.indices {
            for j in garments.indices where j > i {
                let realColor = garments[i].dominantColor
                let otherColor = garments[j].dominantColor
                guard realColor.deltaE2000(to: otherColor) >= distinctRealThreshold else { continue }

                let simDelta = CVDSimulator.simulate(realColor, type: visionType)
                    .deltaE2000(to: CVDSimulator.simulate(otherColor, type: visionType))
                guard simDelta <= confusableSimulatedThreshold else { continue }

                adjacency[i, default: []].insert(j)
                adjacency[j, default: []].insert(i)
            }
        }
        guard !adjacency.isEmpty else { return (0, []) }

        var visited: Set<Int> = []
        var clusters: [ConfusableCluster] = []
        for index in garments.indices where adjacency[index] != nil && !visited.contains(index) {
            var stack = [index]
            var component: [Int] = []
            while let current = stack.popLast() {
                guard visited.insert(current).inserted else { continue }
                component.append(current)
                stack.append(contentsOf: adjacency[current, default: []])
            }
            clusters.append(ConfusableCluster(garments: component.map { garments[$0] }))
        }

        let percentage = Double(adjacency.keys.count) / Double(garments.count)
        return (percentage, clusters.sorted { $0.garments.count > $1.garments.count })
    }

    // MARK: - Huecos

    private static func gaps(for garments: [Garment], distribution: [ColorSlice]) -> [Gap] {
        guard !garments.isEmpty else { return [] }
        var gaps: [Gap] = []

        let hasNeutral = garments.contains { garment in
            let (_, saturation, lightness) = garment.dominantColor.hsl
            return OutfitEngine.isNeutral(basicName: garment.basicName, saturation: saturation, lightness: lightness)
        }
        if !hasNeutral {
            gaps.append(Gap(
                kind: .noNeutrals,
                message: String(
                    localized: "No tienes ningún color neutro (blanco, negro, gris, beige o azul marino): son la base que combina con todo lo demás."
                )
            ))
        }

        let slots = Set(garments.compactMap { $0.category.outfitSlot })
        if slots.contains(.top), !slots.contains(.bottom), !slots.contains(.fullBody) {
            gaps.append(Gap(
                kind: .missingSlot(.bottom),
                message: String(localized: "Tienes partes de arriba pero ninguna de abajo (pantalón o falda) para combinarlas.")
            ))
        } else if slots.contains(.bottom), !slots.contains(.top), !slots.contains(.fullBody) {
            gaps.append(Gap(
                kind: .missingSlot(.top),
                message: String(localized: "Tienes partes de abajo pero ninguna de arriba para combinarlas.")
            ))
        }
        if !slots.contains(.shoes) {
            gaps.append(Gap(
                kind: .missingSlot(.shoes),
                message: String(localized: "No tienes calzado en el armario: no podrás completar un outfit sin él.")
            ))
        }

        if garments.count >= 6, let dominant = distribution.first, dominant.share > 0.5 {
            let percentage = Int((dominant.share * 100).rounded())
            gaps.append(Gap(
                kind: .overConcentration(basicName: dominant.name, share: dominant.share),
                message: String(
                    localized: "Casi el \(percentage)% de tu armario es \(dominant.name.lowercased()): poca variedad de color para combinar."
                )
            ))
        }

        return gaps
    }

    // MARK: - Lista de compra

    /// Básicos versátiles candidatos a recomendación, en orden de prioridad
    /// (neutros primero). El nombre debe existir tal cual en
    /// `ColorCatalog.entries` para que el swatch y el nombre mostrado sean
    /// siempre coherentes con el resto de la app.
    private static let staplesPool: [String] = [
        String(localized: "Negro"),
        String(localized: "Blanco roto"),
        String(localized: "Gris"),
        String(localized: "Azul marino"),
        String(localized: "Camel"),
        String(localized: "Beige"),
        String(localized: "Azul denim"),
        String(localized: "Verde oliva"),
        String(localized: "Burdeos"),
    ]

    private static let warmBasicNames: Set<String> = [
        String(localized: "Rojo"), String(localized: "Naranja"),
        String(localized: "Amarillo"), String(localized: "Marrón"),
    ]
    private static let coolBasicNames: Set<String> = [
        String(localized: "Azul"), String(localized: "Verde"),
        String(localized: "Turquesa"), String(localized: "Morado"),
    ]

    private static func recommendations(
        for garments: [Garment],
        distribution: [ColorSlice],
        gaps: [Gap],
        visionType: ColorVisionType
    ) -> [ColorRecommendation] {
        guard !garments.isEmpty else { return [] }

        let hasNeutralGap = gaps.contains { if case .noNeutrals = $0.kind { return true } else { return false } }
        let shareByBasicName = Dictionary(uniqueKeysWithValues: distribution.map { ($0.name, $0.share) })

        let warmShare = shareByBasicName.filter { warmBasicNames.contains($0.key) }.values.reduce(0, +)
        let coolShare = shareByBasicName.filter { coolBasicNames.contains($0.key) }.values.reduce(0, +)
        let underrepresentedFamily: Set<String>? = {
            guard garments.count >= 4 else { return nil }
            if warmShare < 0.15 { return warmBasicNames }
            if coolShare < 0.15 { return coolBasicNames }
            return nil
        }()

        var scored: [ColorRecommendation] = []

        for name in staplesPool {
            guard let entry = ColorCatalog.entries.first(where: { $0.name == name }) else { continue }
            let candidateColor = LinearRGB(hex: entry.hex)
            let (_, saturation, lightness) = candidateColor.hsl
            let candidateBasicName = ColorNamer.basicName(for: candidateColor)
            let isNeutralCandidate = OutfitEngine.isNeutral(
                basicName: candidateBasicName, saturation: saturation, lightness: lightness
            )

            // Redundancia: ya hay bastante de este color básico, salvo que
            // sea justo el neutro que falta.
            let existingShare = shareByBasicName[candidateBasicName] ?? 0
            if existingShare > 0.3, !(isNeutralCandidate && hasNeutralGap) { continue }

            // Filtro CVD: no recomendar un color que el usuario no podría
            // distinguir de una prenda que ya tiene.
            let confusableWithExisting = visionType != .normal && garments.contains { garment in
                let realDelta = garment.dominantColor.deltaE2000(to: candidateColor)
                guard realDelta >= distinctRealThreshold else { return false }
                let simDelta = CVDSimulator.simulate(garment.dominantColor, type: visionType)
                    .deltaE2000(to: CVDSimulator.simulate(candidateColor, type: visionType))
                return simDelta <= confusableSimulatedThreshold
            }
            if confusableWithExisting { continue }

            let priority: Int
            let reason: String
            if isNeutralCandidate, hasNeutralGap {
                priority = 1
                reason = String(localized: "Te faltan neutros: un \(name.lowercased()) combina con todo lo que ya tienes.")
            } else if let underrepresentedFamily, underrepresentedFamily.contains(candidateBasicName) {
                priority = 2
                reason = String(localized: "Tu armario está descompensado de temperatura de color: un \(name.lowercased()) lo equilibra.")
            } else if existingShare == 0 {
                priority = 3
                reason = String(localized: "Añade variedad: todavía no tienes ningún \(candidateBasicName.lowercased()) en el armario.")
            } else {
                continue
            }

            scored.append(ColorRecommendation(name: name, color: candidateColor.color, reason: reason, priority: priority))
        }

        // Como máximo 2 por nivel de prioridad, para no llenar la lista solo
        // de neutros cuando el hueco de neutros es grande.
        var picked: [ColorRecommendation] = []
        for priority in 1...3 {
            guard picked.count < 4 else { break }
            let tier = scored.filter { $0.priority == priority }
            picked.append(contentsOf: tier.prefix(2))
        }
        return Array(picked.prefix(4))
    }
}
