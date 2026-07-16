//
//  ShoppingModeView.swift
//  colorblindapp
//

import SwiftData
import SwiftUI
import UIKit

/// Modo compra: analiza con la cámara una prenda que estás a punto de
/// comprar en tienda y la compara contra el armario con `OutfitEngine`,
/// sin guardarla, para decidir si combina antes de pagar por ella.
/// Función 100% premium, sin cata gratuita (a diferencia del generador
/// de outfits): es un incentivo explícito para suscribirse.
struct ShoppingModeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(PurchaseManager.self) private var purchaseManager
    @Query(sort: \Garment.createdAt, order: .reverse) private var wardrobe: [Garment]

    @State private var showCamera = false
    @State private var isAnalyzing = false
    @State private var analysis: GarmentAnalyzer.Analysis?
    @State private var selectedDominant: LinearRGB?
    @State private var category: GarmentCategory = .camiseta
    @State private var candidate: Garment?
    @State private var proposals: [OutfitEngine.Proposal] = []
    @State private var errorMessage: String?
    @State private var showPaywall = false
    @State private var justAdded = false

    var body: some View {
        NavigationStack {
            Group {
                if !purchaseManager.isPremium {
                    locked
                } else if let candidate {
                    results(candidate)
                } else if let analysis {
                    review(analysis)
                } else if isAnalyzing {
                    analyzing
                } else {
                    picker
                }
            }
            .navigationTitle("Modo compra")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { data in
                showCamera = false
                if let data {
                    analyze(imageData: data)
                }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(reason: "Modo compra es una función premium: comprueba antes de pagar si una prenda combina con tu armario.")
        }
    }

    // MARK: - Bloqueo premium

    private var locked: some View {
        ContentUnavailableView {
            Label("Modo compra", systemImage: "bag.badge.questionmark")
        } description: {
            Text("Apunta la cámara a una prenda en la tienda y comprueba si combina con tu armario antes de comprarla. Función exclusiva premium.")
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

    // MARK: - Captura

    private var picker: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "bag.badge.questionmark")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Comprueba antes de comprar")
                .font(.title3.bold())
            Text("Haz una foto a la prenda en la tienda y te diremos si combina con lo que ya tienes en el armario.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }

            Spacer()

            Button {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    showCamera = true
                } else {
                    errorMessage = String(localized: "La cámara no está disponible en este dispositivo.")
                }
            } label: {
                Label("Hacer foto", systemImage: "camera")
                    .singleLineFitted()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
    }

    private var analyzing: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Analizando la prenda…")
                .font(.headline)
            Text("Recortando el fondo y detectando el color")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Revisión

    private func review(_ analysis: GarmentAnalyzer.Analysis) -> some View {
        let dominant = selectedDominant ?? analysis.dominant

        return Form {
            Section {
                HStack {
                    Spacer()
                    if let image = UIImage(data: analysis.croppedImagePNG) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 240)
                    }
                    Spacer()
                }
                .listRowBackground(Color(.systemGroupedBackground))
            }

            Section("Color detectado") {
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(dominant.color)
                        .strokeBorder(.quaternary, lineWidth: 1)
                        .frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ColorNamer.descriptiveName(for: dominant))
                            .font(.headline)
                        Text("\(ColorNamer.basicName(for: dominant)) · \(dominant.hexString)")
                            .font(.subheadline.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !analysis.candidates.isEmpty {
                candidatesSection(analysis, current: dominant)
            }

            Section("Categoría") {
                Picker("Tipo de prenda", selection: $category) {
                    ForEach(GarmentCategory.allCases) { category in
                        Text(category.displayName).tag(category)
                    }
                }
            }

            Section {
                Button {
                    compare(analysis, dominant: dominant)
                } label: {
                    Text("¿Combina con mi armario?")
                        .singleLineFitted()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .listRowBackground(Color(.systemGroupedBackground))

                Button("Elegir otra foto") {
                    self.analysis = nil
                    self.selectedDominant = nil
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color(.systemGroupedBackground))
            }
        }
    }

    /// Swatches tocables con los demás colores detectados en la foto, igual
    /// que en la alta de prendas del armario.
    private func candidatesSection(_ analysis: GarmentAnalyzer.Analysis, current: LinearRGB) -> some View {
        Section {
            HStack(spacing: 12) {
                ForEach(Array(([analysis.dominant] + analysis.candidates).enumerated()), id: \.offset) { _, option in
                    let isSelected = option.hexString == current.hexString
                    Button {
                        selectedDominant = option
                    } label: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(option.color)
                            .strokeBorder(isSelected ? Color.accentColor : Color(.quaternaryLabel), lineWidth: isSelected ? 3 : 1)
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(ColorNamer.descriptiveName(for: option))
                }
                Spacer()
            }
        } header: {
            Text("¿No es el color correcto?")
        }
    }

    // MARK: - Resultados

    private func results(_ candidate: Garment) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                candidateHeader(candidate)

                if proposals.isEmpty {
                    ContentUnavailableView {
                        Label("Sin combinaciones", systemImage: "questionmark.circle")
                    } description: {
                        Text("Esta prenda no completa ningún outfit con lo que ya tienes en el armario. Puede que te falte una parte de arriba o de abajo para combinarla.")
                    }
                } else {
                    Text("Así combina con tu armario")
                        .font(.headline)
                        .padding(.horizontal)
                    ForEach(proposals) { proposal in
                        ShoppingProposalCard(proposal: proposal)
                    }
                }

                addToWardrobeButton(candidate)
                startOverButton
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func candidateHeader(_ candidate: Garment) -> some View {
        HStack(spacing: 14) {
            GarmentThumbnail(garment: candidate, side: 64)
            VStack(alignment: .leading, spacing: 2) {
                Text(candidate.descriptiveName)
                    .font(.headline)
                Text(candidate.category.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
    }

    /// Solo aquí, tras ver si combina, se decide si la prenda de tienda pasa
    /// a formar parte del armario de verdad.
    private func addToWardrobeButton(_ candidate: Garment) -> some View {
        Button {
            modelContext.insert(candidate)
            justAdded = true
        } label: {
            Label(
                justAdded ? "Añadida al armario" : "Añadir esta prenda a mi armario",
                systemImage: justAdded ? "checkmark" : "plus"
            )
            .singleLineFitted()
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(justAdded)
        .padding(.horizontal)
    }

    private var startOverButton: some View {
        Button("Escanear otra prenda") {
            candidate = nil
            analysis = nil
            selectedDominant = nil
            proposals = []
            justAdded = false
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }

    // MARK: - Acciones

    private func analyze(imageData: Data) {
        isAnalyzing = true
        errorMessage = nil
        selectedDominant = nil
        Task {
            defer { isAnalyzing = false }
            do {
                let result = try await GarmentAnalyzer.analyze(imageData: imageData)
                analysis = result
                category = result.estimatedCategory ?? .camiseta
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Compara la prenda de tienda (nunca insertada en el `ModelContext`)
    /// contra el armario real, usándola como ancla de `OutfitEngine`.
    private func compare(_ analysis: GarmentAnalyzer.Analysis, dominant: LinearRGB) {
        let newGarment = Garment(
            imageData: analysis.croppedImagePNG,
            dominant: dominant,
            secondary: analysis.secondary,
            category: category
        )
        candidate = newGarment
        proposals = OutfitEngine.proposals(from: wardrobe + [newGarment], anchor: newGarment)
    }
}

/// Tarjeta de una propuesta en modo compra: sin botón de guardar (el outfit
/// aún no es real hasta que la prenda se compre y, si se quiere, se añada
/// al armario).
private struct ShoppingProposalCard: View {
    let proposal: OutfitEngine.Proposal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScoreBadge(score: proposal.score)

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

#Preview {
    ShoppingModeView()
        .environment(PurchaseManager())
        .modelContainer(for: [UserProfile.self, SavedColor.self, Garment.self, Outfit.self], inMemory: true)
}
