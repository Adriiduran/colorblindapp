//
//  SettingsView.swift
//  colorblindapp
//

import SwiftData
import SwiftUI

struct SettingsView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var modelContext
    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Tu perfil de visión") {
                    Picker("Tipo", selection: $profile.visionType) {
                        ForEach(ColorVisionType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    LabeledContent("Origen") {
                        Text(profile.wasSetManually ? "Elegido manualmente" : "Test de la app")
                    }

                    if let testDate = profile.testDate {
                        LabeledContent("Último test") {
                            Text(testDate, style: .date)
                        }
                    }

                    Text(profile.visionType.summary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    // Se habilitará cuando exista el test (hito 2).
                    Button("Repetir el test") {}
                        .disabled(true)

                    Button("Reiniciar onboarding", role: .destructive) {
                        showResetConfirmation = true
                    }
                } footer: {
                    Text("Reiniciar el onboarding borra tu perfil y vuelve a la pantalla inicial.")
                }

                Section {
                    LabeledContent("Versión", value: appVersion)
                } footer: {
                    Text("Esta app no realiza diagnósticos médicos. Si tienes dudas sobre tu visión, consulta a un oftalmólogo.")
                }
            }
            .navigationTitle("Ajustes")
            .confirmationDialog(
                "¿Borrar tu perfil y reiniciar?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Borrar y reiniciar", role: .destructive) {
                    modelContext.delete(profile)
                }
                Button("Cancelar", role: .cancel) {}
            }
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}

#Preview {
    SettingsView(profile: UserProfile(visionType: .deutan, wasSetManually: true))
        .modelContainer(for: [UserProfile.self, SavedColor.self], inMemory: true)
}
