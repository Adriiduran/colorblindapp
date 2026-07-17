//
//  ColorNamingDiagnosticView.swift
//  colorblindapp
//

#if DEBUG
import SwiftUI

/// Ejecuta `ColorCatalog.NamingDiagnostic` sobre una rejilla sintética de
/// tonos de tejido y muestra cobertura, entradas muertas y peores huecos,
/// para afinar el catálogo con datos y no a ojo. Solo en builds de depuración.
struct ColorNamingDiagnosticView: View {
    @State private var report: ColorCatalog.NamingDiagnostic.Report?

    var body: some View {
        List {
            if let report {
                Section("Resumen") {
                    LabeledContent("Nombres distintos usados", value: "\(report.distinctNamesUsed)/\(report.totalNames)")
                    LabeledContent("ΔE2000 medio", value: report.meanDeltaE.formatted(.number.precision(.fractionLength(1))))
                    LabeledContent("ΔE2000 p95", value: report.p95DeltaE.formatted(.number.precision(.fractionLength(1))))
                    LabeledContent("Muestras", value: "\(report.samples.count)")
                }

                Section("Peores huecos") {
                    ForEach(report.worstGaps) { sample in
                        HStack(spacing: 12) {
                            swatch(color: sample.color)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sample.name)
                                    .font(.subheadline.bold())
                                Text(sample.color.hexString)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("ΔE \(sample.deltaE.formatted(.number.precision(.fractionLength(1))))")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section("Entradas muertas (\(report.deadEntries.count))") {
                    if report.deadEntries.isEmpty {
                        Text("Ninguna: todas las entradas del catálogo se usaron al menos una vez.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(report.deadEntries, id: \.self) { name in
                            Text(name)
                        }
                    }
                }

                Section("Nombres dominantes") {
                    ForEach(report.histogram.prefix(15), id: \.name) { entry in
                        LabeledContent(entry.name, value: "\(entry.count)")
                    }
                }
            }
        }
        .navigationTitle("Diagnóstico de nombres")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if report == nil { run() }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Reejecutar", action: run)
            }
        }
    }

    private func run() {
        report = ColorCatalog.NamingDiagnostic.run()
    }

    private func swatch(color: LinearRGB) -> some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(color.color)
            .strokeBorder(.quaternary, lineWidth: 1)
            .frame(width: 28, height: 28)
    }
}

#Preview {
    NavigationStack {
        ColorNamingDiagnosticView()
    }
}
#endif
