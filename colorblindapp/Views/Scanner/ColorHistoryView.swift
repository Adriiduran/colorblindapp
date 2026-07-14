//
//  ColorHistoryView.swift
//  colorblindapp
//

import SwiftData
import SwiftUI

/// Historial de colores guardados desde el escáner, con favoritos.
struct ColorHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(PurchaseManager.self) private var purchaseManager
    @Query(sort: \SavedColor.scannedAt, order: .reverse) private var colors: [SavedColor]

    @State private var showOnlyFavorites = false
    @State private var showPaywall = false

    private var visibleColors: [SavedColor] {
        showOnlyFavorites ? colors.filter(\.isFavorite) : colors
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Group {
                    if visibleColors.isEmpty {
                        ContentUnavailableView(
                            showOnlyFavorites ? "Sin favoritos" : "Historial vacío",
                            systemImage: showOnlyFavorites ? "star" : "clock",
                            description: Text(
                                showOnlyFavorites
                                    ? "Marca colores con la estrella para verlos aquí."
                                    : "Los colores que guardes desde el escáner aparecerán aquí."
                            )
                        )
                    } else {
                        list
                    }
                }
                freeLimitBanner
            }
            .navigationTitle("Historial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .principal) {
                    Picker("Filtro", selection: $showOnlyFavorites) {
                        Text("Todos").tag(false)
                        Text("Favoritos").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 220)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(reason: "El historial gratis guarda tus últimos \(PurchaseManager.freeHistoryLimit) colores.")
            }
        }
    }

    /// Recuerda el límite gratuito del historial, salvo que ya sea premium.
    @ViewBuilder
    private var freeLimitBanner: some View {
        if !purchaseManager.isPremium {
            Button {
                showPaywall = true
            } label: {
                Label(
                    "Historial gratis: últimos \(PurchaseManager.freeHistoryLimit) colores · Hazte premium",
                    systemImage: "lock.fill"
                )
                .singleLineFitted()
                .font(.footnote.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    private var list: some View {
        List {
            ForEach(visibleColors) { saved in
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(saved.color)
                        .strokeBorder(.quaternary, lineWidth: 1)
                        .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(saved.descriptiveName)
                            .font(.headline)
                        Text("\(saved.basicName) · \(saved.hexString)")
                            .font(.subheadline.monospaced())
                            .foregroundStyle(.secondary)
                        Text(saved.scannedAt, format: .dateTime.day().month().hour().minute())
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    Button {
                        saved.isFavorite.toggle()
                    } label: {
                        Image(systemName: saved.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(saved.isFavorite ? .yellow : .secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(saved.isFavorite ? "Quitar de favoritos" : "Añadir a favoritos")
                }
            }
            .onDelete { offsets in
                for offset in offsets {
                    modelContext.delete(visibleColors[offset])
                }
            }
        }
    }
}

#Preview {
    ColorHistoryView()
        .environment(PurchaseManager())
        .modelContainer(for: [UserProfile.self, SavedColor.self], inMemory: true)
}
