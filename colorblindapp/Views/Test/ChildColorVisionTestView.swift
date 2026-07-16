//
//  ChildColorVisionTestView.swift
//  colorblindapp
//

import SwiftUI

/// Versión gamificada del test para niños pequeños: en vez de dígitos,
/// cada lámina talla una figura geométrica y se responde tocando la forma
/// correspondiente. El resultado es siempre transitorio (nunca se guarda),
/// por eso no recibe `onSave`.
struct ChildColorVisionTestView: View {
    @State private var plateIndex = 0
    @State private var answers: [Int: TestShape?] = [:]
    @State private var outcome: TestOutcome?

    var body: some View {
        Group {
            if let outcome {
                TestResultView(outcome: outcome, onRetry: restart)
            } else {
                plateScreen
            }
        }
        .navigationTitle("Test para niños")
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

            IshiharaPlateView(plate: plate, figure: .shape)
                .padding(.horizontal, 24)

            Text("¿Qué figura ves?")
                .font(.headline)

            shapePad(for: plate)
        }
        .padding(.vertical)
    }

    private func shapePad(for plate: TestPlate) -> some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                ForEach(TestShape.allCases) { shape in
                    Button {
                        answer(shape, for: plate)
                    } label: {
                        TestShapeMark(shape: shape)
                            .frame(width: 36, height: 36)
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel(shape.displayName)
                }
            }

            Button {
                answer(nil, for: plate)
            } label: {
                Text("No veo ninguna figura")
                    .singleLineFitted()
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
    }

    private func answer(_ shape: TestShape?, for plate: TestPlate) {
        answers[plate.id] = shape
        if plateIndex + 1 < ColorVisionTest.plates.count {
            withAnimation {
                plateIndex += 1
            }
        } else {
            withAnimation {
                outcome = ColorVisionTest.outcome(forShapes: answers)
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
        ChildColorVisionTestView()
    }
}
