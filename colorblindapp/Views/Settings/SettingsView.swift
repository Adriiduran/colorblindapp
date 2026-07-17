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
    @State private var showGuestTest = false
    @State private var showPaywall = false
    @State private var showManageSubscriptions = false
    @State private var isRestoring = false

    var body: some View {
        NavigationStack {
            Form {
                profileHeaderSection

                premiumSection

                Section("Tu perfil de visión") {
                    Picker("Tipo", selection: $profile.visionType) {
                        ForEach(ColorVisionType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    LabeledContent {
                        Text(profile.wasSetManually ? "Elegido manualmente" : "Test de la app")
                    } label: {
                        SettingsRowLabel(title: "Origen", systemImage: "person.text.rectangle", tint: .gray)
                    }

                    if let testDate = profile.testDate {
                        LabeledContent {
                            Text(testDate, style: .date)
                        } label: {
                            SettingsRowLabel(title: "Último test", systemImage: "calendar", tint: .red)
                        }
                    }
                }

                Section {
                    Button {
                        showTest = true
                    } label: {
                        SettingsRowLabel(title: "Repetir el test", systemImage: "arrow.triangle.2.circlepath", tint: .blue)
                    }

                    Button {
                        showGuestTest = true
                    } label: {
                        SettingsRowLabel(title: "Hacer el test a otra persona", systemImage: "person.2.fill", tint: .orange)
                    }
                } header: {
                    Text("Tests")
                } footer: {
                    Text("Ideal para probar a un familiar o a un niño: el resultado solo se muestra en pantalla, no se guarda.")
                }

                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        SettingsRowLabel(title: "Reiniciar onboarding", systemImage: "trash", tint: .red)
                    }
                } footer: {
                    Text("Reiniciar el onboarding borra tu perfil y vuelve a la pantalla inicial.")
                }

                Section {
                    LabeledContent {
                        Text(appVersion)
                    } label: {
                        SettingsRowLabel(title: "Versión", systemImage: "info.circle", tint: .gray)
                    }
                } header: {
                    Text("Acerca de")
                } footer: {
                    Text("Esta app no realiza diagnósticos médicos. Si tienes dudas sobre tu visión, consulta a un oftalmólogo.")
                }

                #if DEBUG
                Section("Depuración") {
                    Toggle(
                        isOn: Binding(
                            get: { purchaseManager.debugForcePremium },
                            set: { purchaseManager.debugForcePremium = $0 }
                        )
                    ) {
                        SettingsRowLabel(title: "Simular suscripción premium", systemImage: "ladybug", tint: .green)
                    }

                    NavigationLink {
                        GarmentAnalyzerBenchmarkView()
                    } label: {
                        SettingsRowLabel(title: "Benchmark del analizador de color", systemImage: "chart.bar", tint: .purple)
                    }
                }
                #endif
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
            .fullScreenCover(isPresented: $showGuestTest) {
                NavigationStack {
                    GuestTestView()
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

    // MARK: - Cabecera de perfil

    @ViewBuilder
    private var profileHeaderSection: some View {
        Section {
            HStack(spacing: 16) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.accentColor, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.visionType.displayName)
                        .font(.headline)

                    if profile.visionType != .normal, profile.severity != .unknown {
                        Text(profile.severity.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text(profile.visionType.summary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Premium

    @ViewBuilder
    private var premiumSection: some View {
        Section("Premium") {
            if purchaseManager.isPremium {
                if purchaseManager.hasLifetime {
                    SettingsRowLabel(title: "Premium de por vida", systemImage: "checkmark.seal.fill", tint: .green)
                } else {
                    SettingsRowLabel(title: "Suscripción activa", systemImage: "checkmark.seal.fill", tint: .green)

                    Button {
                        showManageSubscriptions = true
                    } label: {
                        SettingsRowLabel(title: "Gestionar suscripción", systemImage: "creditcard", tint: .blue)
                    }
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    SettingsRowLabel(title: "Hazte premium", systemImage: "sparkles", tint: .yellow)
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
                    SettingsRowLabel(title: "Restaurar compras", systemImage: "arrow.clockwise", tint: .gray)
                }
            }
            .disabled(isRestoring)
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}

/// Fila de Ajustes al estilo del sistema: icono en cuadrado de color junto al texto.
private struct SettingsRowLabel: View {
    let title: LocalizedStringKey
    let systemImage: String
    let tint: Color

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(tint, in: RoundedRectangle(cornerRadius: 6))
        }
    }
}

#Preview {
    SettingsView(profile: UserProfile(visionType: .deutan, wasSetManually: true))
        .environment(PurchaseManager())
        .modelContainer(for: [UserProfile.self, SavedColor.self], inMemory: true)
}
