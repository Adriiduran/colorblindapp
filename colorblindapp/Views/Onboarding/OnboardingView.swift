//
//  OnboardingView.swift
//  colorblindapp
//

import SwiftData
import SwiftUI

/// Flujo de onboarding: bienvenida y elección del tipo de daltonismo.
/// El test de láminas (hito 2) se insertará entre ambos pasos; de momento
/// la única vía es la selección manual.
struct OnboardingView: View {
    var body: some View {
        NavigationStack {
            WelcomeStepView()
        }
    }
}

private struct WelcomeStepView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "eye")
                .font(.system(size: 72))
                .foregroundStyle(.tint)

            Text("Tu asistente para el color")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("Identifica cualquier color con la cámara y combina tu ropa con confianza. Para adaptarnos a ti, primero necesitamos saber qué tipo de daltonismo tienes.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            NavigationLink {
                ColorVisionTestView(showsManualOption: true) { outcome in
                    let profile = UserProfile(
                        visionType: outcome.visionType,
                        severity: outcome.severity,
                        testDate: .now
                    )
                    modelContext.insert(profile)
                    // RootView detecta el nuevo perfil y muestra la app principal.
                }
            } label: {
                Text("Hacer el test")
                    .singleLineFitted()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            NavigationLink {
                ManualTypeSelectionView()
            } label: {
                Text("Ya sé mi tipo, elegirlo manualmente")
                    .singleLineFitted()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(32)
    }
}

/// Selección manual del tipo de daltonismo, para quien ya conoce su
/// diagnóstico. Se llega desde la bienvenida o desde un test no concluyente.
struct ManualTypeSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedType: ColorVisionType?

    var body: some View {
        List(ColorVisionType.allCases) { type in
            Button {
                selectedType = type
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(type.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(type.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if selectedType == type {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .navigationTitle("¿Cuál es tu tipo?")
        .safeAreaInset(edge: .bottom) {
            Button {
                completeOnboarding()
            } label: {
                Text("Continuar")
                    .singleLineFitted()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(selectedType == nil)
            .padding()
            .background(.bar)
        }
    }

    private func completeOnboarding() {
        guard let selectedType else { return }
        let profile = UserProfile(visionType: selectedType, wasSetManually: true)
        modelContext.insert(profile)
        // RootView detecta el nuevo perfil y muestra la app principal.
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [UserProfile.self, SavedColor.self], inMemory: true)
}
