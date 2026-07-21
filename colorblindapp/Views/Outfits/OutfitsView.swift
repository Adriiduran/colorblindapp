//
//  OutfitsView.swift
//  colorblindapp
//

import Foundation
import SwiftData
import SwiftUI

/// Generador de outfits: el usuario elige una prenda ancla (o pide una
/// sorpresa) y el motor propone combinaciones puntuadas y explicadas.
struct OutfitsView: View {
    @Query(sort: \Garment.createdAt, order: .reverse) private var garments: [Garment]
    @Environment(\.modelContext) private var modelContext
    @Environment(PurchaseManager.self) private var purchaseManager
    @State private var anchor: Garment?
    @State private var proposals: [OutfitEngine.Proposal] = []
    @State private var hasGenerated = false
    @State private var savedProposalIDs: Set<UUID> = []
    @State private var showPaywall = false

    var body: some View {
        Group {
            if isLockedByTrialCooldown {
                trialCooldownState
            } else if canGenerate {
                generator
            } else {
                emptyState
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Iconos invisibles que replican los del filtro y la
                // auditoría de "Prendas": sin ellos, el trailing toolbar de
                // Outfits (1 icono) pesa menos que el de Prendas (3 iconos) y
                // el segmented de la barra se recoloca al cambiar de sección.
                // sharedBackgroundVisibility(.hidden) evita que el cristal de
                // Liquid Glass se estire cubriendo también estos placeholders.
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .opacity(0)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                Image(systemName: "chart.bar.xaxis")
                    .opacity(0)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .sharedBackgroundVisibility(.hidden)
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
        .sheet(isPresented: $showPaywall) {
            PaywallView(reason: "El generador de outfits es una función premium.")
        }
    }

    // MARK: - Cata gratuita y bloqueo premium

    /// Un usuario no premium que ya ha consumido su generación gratuita de
    /// esta semana (y no está viendo los resultados de esa generación) se
    /// queda bloqueado hasta la próxima semana o hasta hacerse premium.
    private var isLockedByTrialCooldown: Bool {
        !purchaseManager.isPremium && !purchaseManager.canUseFreeOutfitTrial && !hasGenerated
    }

    private var daysUntilNextFreeTrial: Int {
        guard let nextDate = purchaseManager.nextFreeOutfitTrialDate else { return 0 }
        return max(1, Int((nextDate.timeIntervalSinceNow / 86400).rounded(.up)))
    }

    private var daysRemainingText: String {
        daysUntilNextFreeTrial == 1
            ? String(localized: "1 día")
            : String(localized: "\(daysUntilNextFreeTrial) días")
    }

    private var remainingTrialsText: String {
        let remaining = purchaseManager.remainingFreeOutfitTrials
        return remaining == 1
            ? String(localized: "Prueba gratis: te queda 1 generación esta semana.")
            : String(localized: "Prueba gratis: te quedan \(remaining) generaciones esta semana.")
    }

    private var trialCooldownState: some View {
        ContentUnavailableView {
            Label("Generador de outfits", systemImage: "sparkles")
        } description: {
            Text("Ya has usado tu prueba gratis de esta semana. Vuelve en \(daysRemainingText) o hazte premium para generar outfits sin límite.")
        } actions: {
            Button {
                showPaywall = true
            } label: {
                Text("Ver planes premium")
                    .singleLineFitted()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    /// Banner que informa del estado de la cata semanal a un usuario no
    /// premium mientras usa el generador.
    @ViewBuilder
    private var freeTrialBanner: some View {
        if !purchaseManager.isPremium {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "gift.fill")
                    .foregroundStyle(.tint)
                Text(
                    purchaseManager.canUseFreeOutfitTrial
                        ? remainingTrialsText
                        : "Ya has usado tu prueba gratis de esta semana. Vuelve en \(daysRemainingText) o hazte premium."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
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
                freeTrialBanner
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
        VStack(spacing: 10) {
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
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(.horizontal)
    }

    private func generate() {
        if !purchaseManager.isPremium && !purchaseManager.canUseFreeOutfitTrial {
            showPaywall = true
            return
        }
        proposals = OutfitEngine.proposals(from: garments, anchor: anchor)
        hasGenerated = true
        savedProposalIDs = []
        if !purchaseManager.isPremium {
            purchaseManager.consumeFreeOutfitTrial()
        }
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
    NavigationStack {
        OutfitsView()
            .navigationTitle("Outfits")
    }
    .environment(PurchaseManager())
    .modelContainer(for: [UserProfile.self, SavedColor.self, Garment.self, Outfit.self], inMemory: true)
}
