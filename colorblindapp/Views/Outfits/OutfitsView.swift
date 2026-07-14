//
//  OutfitsView.swift
//  colorblindapp
//

import SwiftData
import SwiftUI

/// Generador de outfits: el usuario elige una prenda ancla (o pide una
/// sorpresa) y el motor propone combinaciones puntuadas y explicadas.
struct OutfitsView: View {
    @Query(sort: \Garment.createdAt, order: .reverse) private var garments: [Garment]
    @Environment(\.modelContext) private var modelContext
    @State private var anchor: Garment?
    @State private var proposals: [OutfitEngine.Proposal] = []
    @State private var hasGenerated = false
    @State private var savedProposalIDs: Set<UUID> = []

    var body: some View {
        NavigationStack {
            Group {
                if canGenerate {
                    generator
                } else {
                    emptyState
                }
            }
            .navigationTitle("Outfits")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        SavedOutfitsView()
                    } label: {
                        Image(systemName: "bookmark")
                    }
                    .accessibilityLabel("Outfits guardados")
                }
            }
            // Si el armario cambia, las propuestas pueden apuntar a prendas
            // borradas: se invalida todo y se vuelve a empezar.
            .onChange(of: garments.map(\.persistentModelID)) {
                anchor = nil
                proposals = []
                hasGenerated = false
                savedProposalIDs = []
            }
        }
    }

    // MARK: - Estado del armario

    /// Prendas que participan en el generador (con hueco asignado).
    private var combinable: [Garment] {
        garments.filter { $0.category.outfitSlot != nil }
    }

    /// Hay outfit posible: arriba + abajo, o un vestido.
    private var canGenerate: Bool {
        let slots = Set(combinable.compactMap { $0.category.outfitSlot })
        return slots.contains(.fullBody) || (slots.contains(.top) && slots.contains(.bottom))
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Faltan prendas para combinar", systemImage: "sparkles")
        } description: {
            Text("Para proponerte outfits necesito al menos una parte de arriba y una de abajo (o un vestido) en tu armario.")
        }
    }

    // MARK: - Generador

    private var generator: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                anchorPicker
                actionButtons
                if hasGenerated {
                    results
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var anchorPicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Prenda ancla")
                .font(.headline)
                .padding(.horizontal)
            Text("Elige la prenda que quieres llevar sí o sí, o deja que elijamos por ti.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(combinable) { garment in
                        anchorThumbnail(garment)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
            }
        }
    }

    private func anchorThumbnail(_ garment: Garment) -> some View {
        let isSelected = anchor === garment
        return Button {
            anchor = isSelected ? nil : garment
        } label: {
            VStack(spacing: 4) {
                GarmentThumbnail(garment: garment, side: 72)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.clear), lineWidth: 3)
                    )
                Text(garment.descriptiveName)
                    .font(.caption2)
                    .lineLimit(1)
                    .frame(width: 72)
                    .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(garment.category.displayName) \(garment.descriptiveName)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button {
                generate()
            } label: {
                Label("Proponme outfits", systemImage: "sparkles")
                    .singleLineFitted()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button {
                anchor = combinable.randomElement()
                generate()
            } label: {
                Label("Sorpréndeme", systemImage: "dice")
                    .singleLineFitted()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(.horizontal)
    }

    private func generate() {
        proposals = OutfitEngine.proposals(from: garments, anchor: anchor)
        hasGenerated = true
        savedProposalIDs = []
    }

    // MARK: - Resultados

    @ViewBuilder
    private var results: some View {
        if proposals.isEmpty {
            ContentUnavailableView {
                Label("Sin combinaciones", systemImage: "questionmark.circle")
            } description: {
                Text("Con esa prenda ancla no sale ningún outfit completo. Prueba con otra o añade más prendas.")
            }
        } else {
            Text("Propuestas")
                .font(.headline)
                .padding(.horizontal)
            ForEach(proposals) { proposal in
                OutfitProposalCard(
                    proposal: proposal,
                    isSaved: savedProposalIDs.contains(proposal.id)
                ) {
                    modelContext.insert(
                        Outfit(
                            garments: proposal.garments,
                            score: proposal.score,
                            explanation: proposal.explanation
                        )
                    )
                    savedProposalIDs.insert(proposal.id)
                }
            }
        }
    }
}

/// Tarjeta de una propuesta: prendas juntas, nota sobre 10, explicación y
/// botón de guardar.
struct OutfitProposalCard: View {
    let proposal: OutfitEngine.Proposal
    let isSaved: Bool
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ScoreBadge(score: proposal.score)
                Spacer()
                Button {
                    onSave()
                } label: {
                    Label(
                        isSaved ? "Guardado" : "Guardar",
                        systemImage: isSaved ? "bookmark.fill" : "bookmark"
                    )
                    .singleLineFitted()
                }
                .buttonStyle(.bordered)
                .disabled(isSaved)
            }

            HStack(alignment: .top, spacing: 10) {
                ForEach(proposal.garments) { garment in
                    VStack(spacing: 4) {
                        GarmentThumbnail(garment: garment, side: 76)
                        Text(garment.category.displayName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            Text(proposal.explanation)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

/// Nota del outfit sobre 10, p. ej. "8,2".
struct ScoreBadge: View {
    let score: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "paintpalette.fill")
                .font(.caption)
            Text((score / 10).formatted(.number.precision(.fractionLength(1))))
                .font(.subheadline.weight(.semibold).monospacedDigit())
            Text("/ 10")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(.tertiarySystemFill), in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Puntuación \((score / 10).formatted(.number.precision(.fractionLength(1)))) sobre 10")
    }
}

/// Miniatura cuadrada de una prenda con su fondo de tarjeta.
struct GarmentThumbnail: View {
    let garment: Garment
    let side: CGFloat

    var body: some View {
        Group {
            if let image = UIImage(data: garment.imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "tshirt")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(6)
        .frame(width: side, height: side)
        .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    OutfitsView()
        .modelContainer(for: [UserProfile.self, SavedColor.self, Garment.self, Outfit.self], inMemory: true)
}
