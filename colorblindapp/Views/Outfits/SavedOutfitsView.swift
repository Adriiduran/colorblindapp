//
//  SavedOutfitsView.swift
//  colorblindapp
//

import SwiftData
import SwiftUI

/// Outfits guardados: lista con nota, explicación, marcado de "usado hoy"
/// y borrado por deslizamiento.
struct SavedOutfitsView: View {
    @Query(sort: \Outfit.createdAt, order: .reverse) private var outfits: [Outfit]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if outfits.isEmpty {
                ContentUnavailableView {
                    Label("No hay outfits guardados", systemImage: "bookmark")
                } description: {
                    Text("Guarda tus propuestas favoritas desde el generador y aparecerán aquí.")
                }
            } else {
                List {
                    ForEach(outfits) { outfit in
                        SavedOutfitRow(outfit: outfit)
                    }
                    .onDelete { offsets in
                        for offset in offsets {
                            modelContext.delete(outfits[offset])
                        }
                    }
                }
            }
        }
        .navigationTitle("Outfits guardados")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SavedOutfitRow: View {
    let outfit: Outfit

    /// Nota y explicación recalculadas con las prendas actuales: si el
    /// usuario corrige el color de una prenda (o mejora el catálogo de
    /// nombres), el outfit guardado no se queda con el texto antiguo.
    /// Lo almacenado queda de respaldo para outfits sin prendas.
    private var current: OutfitEngine.Proposal? {
        outfit.garments.isEmpty ? nil : OutfitEngine.evaluate(outfit.sortedGarments)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ScoreBadge(score: current?.score ?? outfit.score)
                Spacer()
                if outfit.wornToday {
                    Label("Usado hoy", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.green)
                        .singleLineFitted()
                }
            }

            if outfit.garments.isEmpty {
                Text("Las prendas de este outfit ya no están en tu armario.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                HStack(alignment: .top, spacing: 8) {
                    ForEach(outfit.sortedGarments) { garment in
                        GarmentThumbnail(garment: garment, side: 56)
                    }
                }
            }

            Text(current?.explanation ?? outfit.explanation)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                outfit.lastWornAt = outfit.wornToday ? nil : .now
            } label: {
                Label(
                    outfit.wornToday ? "Quitar usado hoy" : "Usado hoy",
                    systemImage: outfit.wornToday ? "arrow.uturn.backward" : "checkmark"
                )
                .singleLineFitted()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        SavedOutfitsView()
    }
    .modelContainer(for: [UserProfile.self, SavedColor.self, Garment.self, Outfit.self], inMemory: true)
}
