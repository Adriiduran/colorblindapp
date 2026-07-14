//
//  SettingsView.swift
//  colorblindapp
//

import StoreKit
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var modelContext
    @Environment(PurchaseManager.self) private var purchaseManager
    @State private var showResetConfirmation = false
    @State private var showTest = false
    @State private var showPaywall = false
    @State private var showManageSubscriptions = false
    @State private var isRestoring = false

    var body: some View {
        NavigationStack {
            Form {
                premiumSection

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
                    Button("Repetir el test") {
                        showTest = true
                    }

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
            .fullScreenCover(isPresented: $showTest) {
                NavigationStack {
                    ColorVisionTestView { outcome in
                        profile.visionType = outcome.visionType
                        profile.severity = outcome.severity
                        profile.testDate = .now
                        profile.wasSetManually = false
                        showTest = false
                    }
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancelar") {
                                showTest = false
                            }
                        }
                    }
                }
            }
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
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
        }
    }

    // MARK: - Premium

    @ViewBuilder
    private var premiumSection: some View {
        Section("Premium") {
            if purchaseManager.isPremium {
                Label("Suscripción activa", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)

                Button("Gestionar suscripción") {
                    showManageSubscriptions = true
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Label("Hazte premium", systemImage: "sparkles")
                }

                Text("Armario ilimitado, generador de outfits e historial sin límite.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task {
                    isRestoring = true
                    await purchaseManager.restorePurchases()
                    isRestoring = false
                }
            } label: {
                if isRestoring {
                    ProgressView()
                } else {
                    Text("Restaurar compras")
                }
            }
            .disabled(isRestoring)
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}

#Preview {
    SettingsView(profile: UserProfile(visionType: .deutan, wasSetManually: true))
        .environment(PurchaseManager())
        .modelContainer(for: [UserProfile.self, SavedColor.self], inMemory: true)
}
