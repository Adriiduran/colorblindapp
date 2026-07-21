//
//  WardrobeView.swift
//  colorblindapp
//

import SwiftData
import SwiftUI

/// Armario virtual: catálogo de prendas con su color analizado, filtrable
/// por categoría y por color básico.
struct WardrobeView: View {
    @Query(sort: \Garment.createdAt, order: .reverse) private var garments: [Garment]
    @Environment(\.modelContext) private var modelContext
    @Environment(PurchaseManager.self) private var purchaseManager
    @State private var showAddGarment = false
    @State private var showPaywall = false
    @State private var showAudit = false
    @State private var selectedCategory: GarmentCategory?
    @State private var selectedColorName: String?
    @State private var garmentPendingDeletion: Garment?

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    /// Se alcanzó el límite gratuito de prendas y el usuario no es premium.
    private var reachedFreeLimit: Bool {
        !purchaseManager.isPremium && garments.count >= PurchaseManager.freeWardrobeLimit
    }

    var body: some View {
        Group {
            if garments.isEmpty {
                emptyState
            } else {
                catalog
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Se mantiene siempre presente (solo deshabilitado si el
                // armario está vacío) para que el trailing toolbar no cambie
                // de ancho y el segmented "Prendas | Outfits" de la barra no
                // salte al añadir la primera prenda.
                filterMenu
                    .disabled(garments.isEmpty)
                    .opacity(garments.isEmpty ? 0.4 : 1)
                Button {
                    showAudit = true
                } label: {
                    Image(systemName: "chart.bar.xaxis")
                }
                .disabled(garments.isEmpty)
                .opacity(garments.isEmpty ? 0.4 : 1)
                .accessibilityLabel("Auditoría del armario")
                Button {
                    if reachedFreeLimit {
                        showPaywall = true
                    } else {
                        showAddGarment = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Añadir prenda")
            }
        }
        .sheet(isPresented: $showAddGarment) {
            AddGarmentView()
        }
        .sheet(isPresented: $showAudit) {
            WardrobeAuditView()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(reason: "Tu armario gratis está al completo (\(PurchaseManager.freeWardrobeLimit) prendas). Hazte premium para añadir sin límite.")
        }
        .alert(
            "¿Eliminar esta prenda?",
            isPresented: Binding(
                get: { garmentPendingDeletion != nil },
                set: { if !$0 { garmentPendingDeletion = nil } }
            )
        ) {
            Button("Eliminar", role: .destructive) {
                if let garment = garmentPendingDeletion {
                    modelContext.delete(garment)
                }
                garmentPendingDeletion = nil
            }
            Button("Cancelar", role: .cancel) {
                garmentPendingDeletion = nil
            }
        } message: {
            Text("No se puede deshacer. La prenda también se quitará de los outfits guardados que la incluyan.")
        }
    }

    // MARK: - Filtros

    private var filteredGarments: [Garment] {
        garments.filter { garment in
            (selectedCategory == nil || garment.category == selectedCategory)
                && (selectedColorName == nil || garment.basicName == selectedColorName)
        }
    }

    /// Categorías con al menos una prenda, en el orden del enum.
    private var presentCategories: [GarmentCategory] {
        GarmentCategory.allCases.filter { category in
            garments.contains { $0.category == category }
        }
    }

    /// Colores básicos presentes en el armario, con un color de muestra.
    private var presentColors: [(name: String, color: Color)] {
        var seen = Set<String>()
        return garments
            .compactMap { garment in
                seen.insert(garment.basicName).inserted
                    ? (name: garment.basicName, color: garment.dominantColor.color)
                    : nil
            }
            .sorted { $0.name < $1.name }
    }

    private var hasActiveFilter: Bool {
        selectedCategory != nil || selectedColorName != nil
    }

    /// Menú único que combina el filtro de categoría y el de color.
    private var filterMenu: some View {
        Menu {
            Picker("Categoría", selection: $selectedCategory) {
                Text("Todas").tag(GarmentCategory?.none)
                ForEach(presentCategories) { category in
                    Label(category.displayName, systemImage: category.systemImage)
                        .tag(GarmentCategory?.some(category))
                }
            }
            Picker("Color", selection: $selectedColorName) {
                Text("Todos los colores").tag(String?.none)
                ForEach(presentColors, id: \.name) { entry in
                    Label {
                        Text(entry.name)
                    } icon: {
                        Image(uiImage: Self.dotImage(for: entry.color))
                    }
                    .tag(String?.some(entry.name))
                }
            }
            if hasActiveFilter {
                Divider()
                Button("Quitar filtros", role: .destructive) {
                    selectedCategory = nil
                    selectedColorName = nil
                }
            }
        } label: {
            Image(systemName: hasActiveFilter
                ? "line.3.horizontal.decrease.circle.fill"
                : "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel("Filtros")
    }

    /// Círculo de color como imagen "original" — es la única forma de que
    /// un menú muestre el color real en vez de teñir el icono.
    private static func dotImage(for color: Color) -> UIImage {
        let size = CGSize(width: 20, height: 20)
        return UIGraphicsImageRenderer(size: size).image { context in
            UIColor(color).setFill()
            context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
        }
        .withRenderingMode(.alwaysOriginal)
    }

    /// Fila de tokens quitables con los filtros activos (categoría y/o color).
    @ViewBuilder
    private var activeFilterTokens: some View {
        if hasActiveFilter {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if let category = selectedCategory {
                        filterToken(dot: nil, label: category.displayName) {
                            selectedCategory = nil
                        }
                    }
                    if let colorName = selectedColorName {
                        let color = presentColors.first { $0.name == colorName }?.color
                        filterToken(dot: color, label: colorName) {
                            selectedColorName = nil
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
    }

    private func filterToken(dot: Color?, label: String, remove: @escaping () -> Void) -> some View {
        Button(action: remove) {
            HStack(spacing: 6) {
                if let dot {
                    Circle()
                        .fill(dot)
                        .strokeBorder(.quaternary, lineWidth: 1)
                        .frame(width: 12, height: 12)
                }
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .singleLineFitted()
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .imageScale(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(.primary)
            .background(Color(.secondarySystemFill), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Contenido

    private var catalog: some View {
        VStack(spacing: 0) {
            activeFilterTokens
            if filteredGarments.isEmpty {
                filteredEmptyState
            } else {
                grid
            }
            freeLimitBanner
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Tu armario está vacío", systemImage: "tshirt")
        } description: {
            Text("Añade fotos de tu ropa y detectaremos el color de cada prenda para ayudarte a combinarlas.")
        } actions: {
            Button {
                showAddGarment = true
            } label: {
                Text("Añadir mi primera prenda")
                    .singleLineFitted()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    /// Aviso al pie del catálogo cuando el armario gratis está lleno.
    @ViewBuilder
    private var freeLimitBanner: some View {
        if reachedFreeLimit {
            Button {
                showPaywall = true
            } label: {
                Label(
                    "Armario gratis completo (\(PurchaseManager.freeWardrobeLimit) prendas) · Hazte premium",
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

    private var filteredEmptyState: some View {
        ContentUnavailableView {
            Label("Sin resultados", systemImage: "line.3.horizontal.decrease.circle")
        } description: {
            Text("No hay prendas que coincidan con los filtros.")
        } actions: {
            Button("Quitar filtros") {
                selectedCategory = nil
                selectedColorName = nil
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(filteredGarments) { garment in
                    NavigationLink {
                        GarmentDetailView(garment: garment)
                    } label: {
                        GarmentCard(garment: garment)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            garmentPendingDeletion = garment
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
    }
}

/// Tarjeta de prenda: foto recortada, color y categoría.
struct GarmentCard: View {
    let garment: Garment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if let image = UIImage(data: garment.imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "tshirt")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .padding(8)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 8) {
                Circle()
                    .fill(garment.dominantColor.color)
                    .strokeBorder(.quaternary, lineWidth: 1)
                    .frame(width: 16, height: 16)
                if let secondary = garment.secondaryColor {
                    Circle()
                        .fill(secondary.color)
                        .strokeBorder(.quaternary, lineWidth: 1)
                        .frame(width: 12, height: 12)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(garment.descriptiveName)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                    Text(garment.category.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        WardrobeView()
    }
    .environment(PurchaseManager())
    .modelContainer(for: [UserProfile.self, SavedColor.self, Garment.self], inMemory: true)
}
