//
//  TestResultView.swift
//  colorblindapp
//

import SwiftUI

struct TestResultView: View {
    let outcome: TestOutcome
    var showsManualOption = false
    let onSave: () -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            if outcome.isConclusive {
                conclusiveContent
            } else {
                inconclusiveContent
            }

            Spacer()

            Text("Este test es orientativo y no sustituye un diagnóstico médico. Si tienes dudas, consulta a un oftalmólogo.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            actionButtons
        }
        .padding(24)
    }

    @ViewBuilder
    private var conclusiveContent: some View {
        Image(systemName: outcome.visionType == .normal ? "checkmark.circle" : "eye")
            .font(.system(size: 64))
            .foregroundStyle(.tint)

        Text(outcome.visionType.displayName)
            .font(.largeTitle.bold())
            .multilineTextAlignment(.center)

        if outcome.visionType != .normal, outcome.severity != .unknown {
            Text("Intensidad: \(outcome.severity.displayName)")
                .font(.headline)
                .foregroundStyle(.secondary)
        }

        Text(outcome.visionType.summary)
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private var inconclusiveContent: some View {
        Image(systemName: "questionmark.circle")
            .font(.system(size: 64))
            .foregroundStyle(.orange)

        Text("Resultado no concluyente")
            .font(.largeTitle.bold())
            .multilineTextAlignment(.center)

        Text("Fallaste alguna de las láminas de control que todo el mundo debería ver. Puede que la pantalla tuviera reflejos o el brillo bajo. Busca buena luz, sube el brillo y vuelve a intentarlo.")
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private var actionButtons: some View {
        if outcome.isConclusive {
            Button(action: onSave) {
                Text("Guardar mi perfil")
                    .singleLineFitted()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }

        Button(action: onRetry) {
            Text("Repetir el test")
                .singleLineFitted()
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)

        if showsManualOption {
            NavigationLink {
                ManualTypeSelectionView()
            } label: {
                Text("Elegir mi tipo manualmente")
                    .singleLineFitted()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderless)
        }
    }
}

#Preview("Concluyente") {
    NavigationStack {
        TestResultView(
            outcome: TestOutcome(isConclusive: true, visionType: .deutan, severity: .mild),
            showsManualOption: true,
            onSave: {},
            onRetry: {}
        )
    }
}

#Preview("No concluyente") {
    NavigationStack {
        TestResultView(
            outcome: TestOutcome(isConclusive: false, visionType: .normal, severity: .unknown),
            onSave: {},
            onRetry: {}
        )
    }
}
