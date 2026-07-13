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
    @State private var showAddGarment = false
    @State private var selectedCategory: GarmentCategory?
    @State private var selectedColorName: String?

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        NavigationStack {
            Group {
                if garments.isEmpty {
                    emptyState
                } else {
                    catalog
                }
            }
            .navigationTitle("Armario")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    if !garments.isEmpty {
                        colorFilterMenu
                    }
                    Button {
                        showAddGarment = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Añadir prenda")
                }
            }
            .sheet(isPresented: $showAddGarment) {
                AddGarmentView()
            }
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

    private var colorFilterMenu: some View {
        Menu {
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
        } label: {
            Image(systemName: selectedColorName == nil ? "paintpalette" : "paintpalette.fill")
        }
        .accessibilityLabel("Filtrar por color")
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

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: String(localized: "Todas"), isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(presentCategories) { category in
                    chip(title: category.displayName, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func chip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .singleLineFitted()
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
                .background(
                    isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(Color(.secondarySystemFill)),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Contenido

    private var catalog: some View {
        VStack(spacing: 0) {
            categoryChips
            if filteredGarments.isEmpty {
                filteredEmptyState
            } else {
                grid
            }
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
                            modelContext.delete(garment)
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
    WardrobeView()
        .modelContainer(for: [UserProfile.self, SavedColor.self, Garment.self], inMemory: true)
}
