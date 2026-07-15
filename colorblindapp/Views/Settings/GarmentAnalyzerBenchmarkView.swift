//
//  GarmentAnalyzerBenchmarkView.swift
//  colorblindapp
//

#if DEBUG
import SwiftUI

/// Ejecuta `GarmentAnalyzer.Benchmark` sobre escenas sintéticas y muestra
/// acierto de categoría y ΔE por caso, para iterar el extractor de color
/// con datos y no a ojo. Solo en builds de depuración.
struct GarmentAnalyzerBenchmarkView: View {
    @State private var results: [GarmentAnalyzer.Benchmark.Result] = []

    var body: some View {
        List {
            Section {
                LabeledContent("Aciertos", value: "\(passedCount)/\(results.count)")
                LabeledContent("ΔE medio", value: averageDeltaE.formatted(.number.precision(.fractionLength(1))))
            }

            Section("Casos") {
                ForEach(results) { result in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(result.passed ? .green : .red)
                            Text(result.name)
                                .font(.subheadline.bold())
                        }
                        HStack(spacing: 12) {
                            swatch(hex: result.expectedHex, label: "Esperado: \(result.expectedBasic)")
                            swatch(hex: result.gotHex, label: "Obtenido: \(result.gotBasic)")
                        }
                        Text("ΔE \(result.deltaE.formatted(.number.precision(.fractionLength(1))))")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Benchmark de color")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if results.isEmpty { run() }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Reejecutar", action: run)
            }
        }
    }

    private func run() {
        results = GarmentAnalyzer.Benchmark.run()
    }

    private var passedCount: Int {
        results.count(where: \.passed)
    }

    private var averageDeltaE: Double {
        guard !results.isEmpty else { return 0 }
        return results.reduce(0) { $0 + $1.deltaE } / Double(results.count)
    }

    private func swatch(hex: String, label: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 5)
                .fill(LinearRGB(hex: hex).color)
                .strokeBorder(.quaternary, lineWidth: 1)
                .frame(width: 20, height: 20)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        GarmentAnalyzerBenchmarkView()
    }
}
#endif
