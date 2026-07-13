//
//  ColorVisionTestView.swift
//  colorblindapp
//

import SwiftUI

/// Test de daltonismo: muestra las láminas una a una y termina en la
/// pantalla de resultado. `showsManualOption` añade en el resultado la
/// salida hacia la selección manual (solo tiene sentido en onboarding).
struct ColorVisionTestView: View {
    var showsManualOption = false
    let onSave: (TestOutcome) -> Void

    @State private var plateIndex = 0
    @State private var answers: [Int: Int?] = [:]
    @State private var outcome: TestOutcome?

    var body: some View {
        Group {
            if let outcome {
                TestResultView(
                    outcome: outcome,
                    showsManualOption: showsManualOption,
                    onSave: { onSave(outcome) },
                    onRetry: restart
                )
            } else {
                plateScreen
            }
        }
        .navigationTitle("Test de daltonismo")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var plateScreen: some View {
        let plate = ColorVisionTest.plates[plateIndex]
        return VStack(spacing: 16) {
            ProgressView(value: Double(plateIndex), total: Double(ColorVisionTest.plates.count))
                .padding(.horizontal)

            Text("Lámina \(plateIndex + 1) de \(ColorVisionTest.plates.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            IshiharaPlateView(plate: plate)
                .padding(.horizontal, 24)

            Text("¿Qué número ves?")
                .font(.headline)

            keypad(for: plate)
        }
        .padding(.vertical)
    }

    private func keypad(for plate: TestPlate) -> some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                ForEach(0...9, id: \.self) { number in
                    Button {
                        answer(number, for: plate)
                    } label: {
                        Text("\(number)")
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.bordered)
                }
            }

            Button {
                answer(nil, for: plate)
            } label: {
                Text("No veo ningún número")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
    }

    private func answer(_ digit: Int?, for plate: TestPlate) {
        answers[plate.id] = digit
        if plateIndex + 1 < ColorVisionTest.plates.count {
            withAnimation {
                plateIndex += 1
            }
        } else {
            withAnimation {
                outcome = ColorVisionTest.outcome(for: answers)
            }
        }
    }

    private func restart() {
        withAnimation {
            answers = [:]
            plateIndex = 0
            outcome = nil
        }
    }
}

#Preview {
    NavigationStack {
        ColorVisionTestView(showsManualOption: true) { _ in }
    }
}
