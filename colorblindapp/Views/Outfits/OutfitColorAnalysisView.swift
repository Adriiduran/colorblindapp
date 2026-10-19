//
//  OutfitColorAnalysisView.swift
//  colorblindapp
//

import SwiftUI
import SwiftData

/// Si esta prenda cuenta como neutro para la colorimetría (blanco, negro,
/// gris, beige, azul marino apagado) — mismo criterio que el motor de
/// outfits, reutilizado aquí para agrupar los neutros en el centro de la
/// rueda y anotarlos como "Neutro" en la leyenda.
private func isNeutralGarment(_ garment: Garment) -> Bool {
    let (_, saturation, lightness) = garment.dominantColor.hsl
    return OutfitEngine.isNeutral(basicName: garment.basicName, saturation: saturation, lightness: lightness)
}

/// Modo de descripción avanzada de una propuesta de outfit: la colorimetría
/// estructurada detrás de la nota y la explicación, con una rueda de color a
/// modo de apoyo visual. La rueda nunca es la única fuente de información:
/// todo lo que transmite (tono, esquema, neutros) se repite en texto, tanto
/// para VoiceOver como para quien no distinga los colores dibujados.
struct OutfitColorAnalysisView: View {
    let proposal: OutfitEngine.Proposal

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if proposal.garments.count > 1 {
                        ColorWheel(garments: proposal.garments, harmonies: proposal.harmonies)
                            .frame(width: 240, height: 240)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }

                    if !proposal.harmonies.isEmpty {
                        schemeSection
                    }

                    legendSection
                    explanationSection
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Colorimetría del outfit")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
    }

    // MARK: - Cabecera

    private var header: some View {
        HStack {
            ScoreBadge(score: proposal.score)
            Spacer()
        }
        .padding(.horizontal)
    }

    // MARK: - Esquema

    /// Relaciones deduplicadas por tipo (mismo criterio que
    /// `OutfitEngine.explanation`), como máximo 3, ya vienen ordenadas por
    /// peso y puntuación desde `OutfitEngine.evaluate`.
    private var dedupedHarmonies: [OutfitEngine.HarmonyRelation] {
        var seenKinds: Set<OutfitEngine.HarmonyKind> = []
        var result: [OutfitEngine.HarmonyRelation] = []
        for relation in proposal.harmonies {
            guard seenKinds.insert(relation.kind).inserted else { continue }
            result.append(relation)
            if result.count == 3 { break }
        }
        return result
    }

    private var schemeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Esquema de color")
                .font(.headline)
                .padding(.horizontal)
            VStack(spacing: 10) {
                ForEach(dedupedHarmonies) { relation in
                    schemeRow(relation)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }

    private func schemeRow(_ relation: OutfitEngine.HarmonyRelation) -> some View {
        HStack(alignment: .top, spacing: 12) {
            swatchPair(relation)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(relation.kind.title)
                        .font(.subheadline.weight(.semibold))
                    if !relation.kind.isHarmonious {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
                Text(relation.kind.concept)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func swatchPair(_ relation: OutfitEngine.HarmonyRelation) -> some View {
        HStack(spacing: -8) {
            Circle()
                .fill(relation.first.dominantColor.color)
                .strokeBorder(Color(.secondarySystemGroupedBackground), lineWidth: 2)
                .frame(width: 24, height: 24)
            Circle()
                .fill(relation.second.dominantColor.color)
                .strokeBorder(Color(.secondarySystemGroupedBackground), lineWidth: 2)
                .frame(width: 24, height: 24)
        }
    }

    // MARK: - Leyenda

    private var legendSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Prendas")
                .font(.headline)
                .padding(.horizontal)
            VStack(spacing: 10) {
                ForEach(proposal.garments) { garment in
                    legendRow(garment)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }

    private func legendRow(_ garment: Garment) -> some View {
        let hsl = garment.dominantColor.hsl
        let isNeutral = isNeutralGarment(garment)
        return HStack(spacing: 12) {
            Circle()
                .fill(garment.dominantColor.color)
                .strokeBorder(.quaternary, lineWidth: 1)
                .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(garment.descriptiveName)
                    .font(.subheadline)
                    .singleLineFitted()
                Text(garment.category.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(isNeutral ? "Neutro" : "\(Int(hsl.hue.rounded()))°")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Explicación

    private var explanationSection: some View {
        Text(proposal.explanation)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal)
    }
}

/// Rueda de color: un anillo con el espectro de tono y un punto por cada
/// prenda de la propuesta, en su posición de tono/saturación. Los neutros
/// (sin tono con sentido) se agrupan en el disco central en vez de
/// dispersarse con un tono arbitrario. Las líneas unen las prendas de cada
/// relación de armonía — firmes si son una armonía sólida, discontinuas y en
/// naranja si son un caso débil (`HarmonyKind.isHarmonious == false`).
///
/// Es puramente decorativa: toda la información que muestra ya está en el
/// esquema y la leyenda en texto, así que se oculta a VoiceOver en vez de
/// duplicar la descripción.
private struct ColorWheel: View {
    let garments: [Garment]
    let harmonies: [OutfitEngine.HarmonyRelation]

    private let size: CGFloat = 240
    private let ringWidth: CGFloat = 22
    private let neutralRadius: CGFloat = 40
    private let markerDiameter: CGFloat = 22

    private var center: CGPoint { CGPoint(x: size / 2, y: size / 2) }
    private var ringRadius: CGFloat { size / 2 - ringWidth / 2 }
    private var markerInnerRadius: CGFloat { neutralRadius + markerDiameter / 2 + 6 }
    private var markerOuterRadius: CGFloat { ringRadius - ringWidth / 2 - markerDiameter / 2 - 4 }

    private static let spectrum: [Color] = stride(from: 0.0, through: 360, by: 30).map {
        Color(hue: $0 / 360, saturation: 0.85, brightness: 0.9)
    }

    private struct Marker {
        let garment: Garment
        let position: CGPoint
    }

    /// Posición de cada prenda: los neutros se reparten en un pequeño
    /// círculo dentro del disco central; el resto se coloca por tono
    /// (ángulo) y saturación (radio, entre el disco central y el anillo).
    private var markers: [Marker] {
        let neutrals = garments.filter(isNeutralGarment)
        let chromatic = garments.filter { !isNeutralGarment($0) }

        var result: [Marker] = []
        for (index, garment) in neutrals.enumerated() {
            let position: CGPoint
            if neutrals.count == 1 {
                position = center
            } else {
                let angle = Double(index) / Double(neutrals.count) * 2 * .pi
                let r = neutralRadius * 0.5
                position = CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
            }
            result.append(Marker(garment: garment, position: position))
        }
        for garment in chromatic {
            let (hue, saturation, _) = garment.dominantColor.hsl
            let theta = (hue - 90) * .pi / 180
            let r = markerInnerRadius + CGFloat(min(max(saturation, 0), 1)) * (markerOuterRadius - markerInnerRadius)
            let position = CGPoint(x: center.x + r * cos(theta), y: center.y + r * sin(theta))
            result.append(Marker(garment: garment, position: position))
        }
        return result
    }

    private var hasNeutral: Bool {
        garments.contains(where: isNeutralGarment)
    }

    private struct Line: Identifiable {
        let id = UUID()
        let from: CGPoint
        let to: CGPoint
        let isHarmonious: Bool
    }

    private var lines: [Line] {
        let positions = Dictionary(uniqueKeysWithValues: markers.map { ($0.garment.persistentModelID, $0.position) })
        return harmonies.compactMap { relation in
            guard let from = positions[relation.first.persistentModelID],
                  let to = positions[relation.second.persistentModelID] else { return nil }
            return Line(from: from, to: to, isHarmonious: relation.kind.isHarmonious)
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: Self.spectrum,
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    lineWidth: ringWidth
                )

            Circle()
                .fill(Color(.tertiarySystemFill))
                .frame(width: neutralRadius * 2, height: neutralRadius * 2)

            if hasNeutral {
                Text("Neutros")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(width: neutralRadius * 1.6)
                    .multilineTextAlignment(.center)
            }

            ForEach(lines) { line in
                Path { path in
                    path.move(to: line.from)
                    path.addLine(to: line.to)
                }
                .stroke(
                    line.isHarmonious ? AnyShapeStyle(.secondary) : AnyShapeStyle(.orange),
                    style: StrokeStyle(lineWidth: 1.5, dash: line.isHarmonious ? [] : [4, 3])
                )
            }

            ForEach(markers, id: \.garment.persistentModelID) { marker in
                Circle()
                    .fill(marker.garment.dominantColor.color)
                    .strokeBorder(.background, lineWidth: 2)
                    .frame(width: markerDiameter, height: markerDiameter)
                    .position(marker.position)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

#Preview {
    let a = Garment(imageData: Data(), dominant: LinearRGB(hex: "#C8262A"), secondary: nil, category: .camiseta)
    let b = Garment(imageData: Data(), dominant: LinearRGB(hex: "#1B2A6B"), secondary: nil, category: .pantalon)
    let c = Garment(imageData: Data(), dominant: LinearRGB(hex: "#EDEDED"), secondary: nil, category: .zapatos)
    let proposal = OutfitEngine.evaluate([a, b, c])
    return OutfitColorAnalysisView(proposal: proposal)
}
