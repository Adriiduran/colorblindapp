//
//  AddGarmentView.swift
//  colorblindapp
//

import PhotosUI
import SwiftData
import SwiftUI

/// Alta de una prenda: elegir foto, recorte y análisis de color
/// automáticos, revisión y guardado.
struct AddGarmentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selection: PhotosPickerItem?
    @State private var isAnalyzing = false
    @State private var analysis: GarmentAnalyzer.Analysis?
    @State private var selectedDominant: LinearRGB?
    @State private var category: GarmentCategory = .camiseta
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if let analysis {
                    review(analysis)
                } else if isAnalyzing {
                    analyzing
                } else {
                    picker
                }
            }
            .navigationTitle("Nueva prenda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: selection) {
            guard let selection else { return }
            analyze(selection)
        }
    }

    // MARK: - Selección

    private var picker: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "tshirt")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Añade una foto de tu prenda")
                .font(.title3.bold())
            Text("Recortaremos la prenda del fondo y detectaremos su color automáticamente. Funciona mejor con la prenda extendida sobre un fondo liso.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }

            Spacer()

            PhotosPicker(selection: $selection, matching: .images) {
                Label("Elegir foto", systemImage: "photo.on.rectangle")
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

                if let secondary = analysis.secondary {
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
                    save(analysis, dominant: dominant)
                } label: {
                    Text("Guardar en el armario")
                        .singleLineFitted()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .listRowBackground(Color(.systemGroupedBackground))

                Button("Elegir otra foto") {
                    self.analysis = nil
                    self.selectedDominant = nil
                    self.selection = nil
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color(.systemGroupedBackground))
            }
        }
    }

    /// Swatches tocables con los demás colores detectados en la foto, para
    /// corregir con un toque cuando el algoritmo elige el color equivocado
    /// (p. ej. una sombra o un estampado) sin tener que abrir el selector.
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
        } footer: {
            Text("Toca otro de los colores detectados en la foto, o ajusta el color a mano desde la ficha de la prenda tras guardarla.")
        }
    }

    // MARK: - Acciones

    private func analyze(_ item: PhotosPickerItem) {
        isAnalyzing = true
        errorMessage = nil
        selectedDominant = nil
        Task {
            defer { isAnalyzing = false }
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    throw GarmentAnalyzer.AnalysisError.invalidImage
                }
                analysis = try await GarmentAnalyzer.analyze(imageData: data)
            } catch {
                errorMessage = error.localizedDescription
                selection = nil
            }
        }
    }

    private func save(_ analysis: GarmentAnalyzer.Analysis, dominant: LinearRGB) {
        let garment = Garment(
            imageData: analysis.croppedImagePNG,
            dominant: dominant,
            secondary: analysis.secondary,
            category: category
        )
        modelContext.insert(garment)
        dismiss()
    }
}

#Preview {
    AddGarmentView()
        .modelContainer(for: [UserProfile.self, SavedColor.self, Garment.self], inMemory: true)
}
