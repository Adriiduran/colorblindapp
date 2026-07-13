//
//  WardrobeView.swift
//  colorblindapp
//

import SwiftData
import SwiftUI

/// Armario virtual: catálogo de prendas con su color analizado.
struct WardrobeView: View {
    @Query(sort: \Garment.createdAt, order: .reverse) private var garments: [Garment]
    @Environment(\.modelContext) private var modelContext
    @State private var showAddGarment = false

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        NavigationStack {
            Group {
                if garments.isEmpty {
                    emptyState
                } else {
                    grid
                }
            }
            .navigationTitle("Armario")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
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

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(garments) { garment in
                    GarmentCard(garment: garment)
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
