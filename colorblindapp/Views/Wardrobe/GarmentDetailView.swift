//
//  GarmentDetailView.swift
//  colorblindapp
//

import SwiftData
import SwiftUI

/// Ficha de una prenda: foto recortada, color detectado (corregible por el
/// usuario) y categoría editable.
struct GarmentDetailView: View {
    @Bindable var garment: Garment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false

    var body: some View {
        Form {
            photoSection
            colorSection
            correctionSection
            categorySection
            deleteSection
        }
        .navigationTitle(garment.descriptiveName)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "¿Eliminar esta prenda?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Eliminar prenda", role: .destructive) {
                modelContext.delete(garment)
                dismiss()
            }
            Button("Cancelar", role: .cancel) {}
        }
    }

    // MARK: - Secciones

    private var photoSection: some View {
        Section {
            HStack {
                Spacer()
                if let image = UIImage(data: garment.imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 240)
                } else {
                    Image(systemName: garment.category.systemImage)
                        .font(.system(size: 56))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .listRowBackground(Color(.systemGroupedBackground))
        }
    }

    private var colorSection: some View {
        Section("Color") {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(garment.dominantColor.color)
                    .strokeBorder(.quaternary, lineWidth: 1)
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(garment.descriptiveName)
                        .font(.headline)
                    Text("\(garment.basicName) · \(garment.dominantColor.hexString)")
                        .font(.subheadline.monospaced())
                        .foregroundStyle(.secondary)
                }
            }

            if let secondary = garment.secondaryColor {
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(secondary.color)
                        .strokeBorder(.quaternary, lineWidth: 1)
                        .frame(width: 32, height: 32)
                    Text("Color secundario: \(ColorNamer.descriptiveName(for: secondary))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var correctionSection: some View {
        Section {
            if garment.secondaryColor != nil {
                Button {
                    withAnimation {
                        garment.swapWithSecondary()
                    }
                } label: {
                    Label("Usar el color secundario como principal", systemImage: "arrow.triangle.2.circlepath")
                        .singleLineFitted()
                }
            }

            ColorPicker(selection: pickedColor, supportsOpacity: false) {
                Label("Elegir el color a mano", systemImage: "eyedropper")
            }
        } header: {
            Text("¿El color no es correcto?")
        } footer: {
            Text("Si la foto engañó al análisis, corrige aquí el color de la prenda. El nombre se recalcula automáticamente.")
        }
    }

    private var categorySection: some View {
        Section("Categoría") {
            Picker("Tipo de prenda", selection: $garment.category) {
                ForEach(GarmentCategory.allCases) { category in
                    Text(category.displayName).tag(category)
                }
            }
        }
    }

    private var deleteSection: some View {
        Section {
            Button("Eliminar prenda", role: .destructive) {
                showDeleteConfirmation = true
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Corrección manual

    /// Puente entre el `ColorPicker` (sRGB de sistema) y el modelo (RGB
    /// lineal). Al escribir se recalculan los nombres vía `setDominant`.
    private var pickedColor: Binding<Color> {
        Binding {
            garment.dominantColor.color
        } set: { newValue in
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            UIColor(newValue).getRed(&r, green: &g, blue: &b, alpha: &a)
            func clamp(_ v: CGFloat) -> Double { Double(min(max(v, 0), 1)) }
            garment.setDominant(LinearRGB(srgbRed: clamp(r), srgbGreen: clamp(g), srgbBlue: clamp(b)))
        }
    }
}
