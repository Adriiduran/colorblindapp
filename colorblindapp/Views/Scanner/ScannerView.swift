//
//  ScannerView.swift
//  colorblindapp
//

import SwiftData
import SwiftUI

/// Escáner de color: apunta la cámara y muestra el color del centro en
/// tres formas (hex, básico y descriptivo), con aviso de confusión según
/// el perfil del usuario y guardado en el historial.
struct ScannerView: View {
    @State private var model = ScannerModel()
    @State private var showHistory = false
    @State private var showShoppingMode = false
    @State private var justSaved = false
    @Environment(\.modelContext) private var modelContext
    @Environment(PurchaseManager.self) private var purchaseManager
    @Query private var profiles: [UserProfile]
    @Query(sort: \SavedColor.scannedAt, order: .forward) private var savedColors: [SavedColor]

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(model.authorization == .authorized ? "" : "Escáner")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(model.authorization == .authorized ? .hidden : .automatic, for: .navigationBar)
                .toolbar {
                    if model.authorization == .authorized {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showHistory = true
                            } label: {
                                Image(systemName: "clock")
                            }
                            .accessibilityLabel("Historial")
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showShoppingMode = true
                            } label: {
                                Image(systemName: "bag.badge.questionmark")
                            }
                            .accessibilityLabel("Modo compra")
                        }
                    }
                }
        }
        .onAppear {
            model.refreshAuthorization()
            model.start()
        }
        .onDisappear {
            model.stop()
        }
        .sheet(isPresented: $showHistory) {
            ColorHistoryView()
        }
        .sheet(isPresented: $showShoppingMode) {
            ShoppingModeView()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.authorization {
        case .authorized:
            scanner
        case .undetermined:
            permissionExplainer
        case .denied:
            permissionDenied
        }
    }

    // MARK: - Escáner

    private var scanner: some View {
        GeometryReader { geometry in
            // Alto total de la pantalla: el visor la cubre entera (aspectFill),
            // así que mirilla-en-puntos / lado-largo = región-en-píxeles / frame.
            let viewLongSide = geometry.size.height
                + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom

            ZStack(alignment: .bottom) {
                // El visor y la mirilla ignoran las zonas seguras: el vídeo
                // llega hasta detrás del tab bar y la mirilla queda clavada en
                // el centro real del frame muestreado.
                ZStack {
                    viewfinder
                    reticle
                }
                .ignoresSafeArea()

                readoutPanel
            }
            .overlay(alignment: .topLeading) {
                if model.isDemoMode {
                    Text("MODO DEMO")
                        .font(.caption2.bold())
                        .padding(6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding()
                }
            }
            .onAppear {
                model.updateViewLongSide(viewLongSide)
            }
            .onChange(of: viewLongSide) {
                model.updateViewLongSide(viewLongSide)
            }
            .onChange(of: model.reticleSize) {
                model.applySamplingRegion()
            }
        }
    }

    @ViewBuilder
    private var viewfinder: some View {
        if model.isDemoMode {
            // En el simulador no hay cámara: el "mundo" es el propio color demo.
            Rectangle()
                .fill(model.color?.color ?? .black)
                .animation(.easeInOut(duration: 0.5), value: model.color?.hexString)
        } else if let session = model.captureSession {
            CameraPreviewView(session: session)
        } else {
            ContentUnavailableView(
                "Cámara no disponible",
                systemImage: "video.slash",
                description: Text("No se pudo acceder a la cámara de este dispositivo.")
            )
        }
    }

    private var reticle: some View {
        ZStack {
            Circle()
                .stroke(.black.opacity(0.4), lineWidth: 4)
                .frame(width: model.reticleSize + 2, height: model.reticleSize + 2)
            Circle()
                .stroke(.white, lineWidth: 2)
                .frame(width: model.reticleSize, height: model.reticleSize)
            if model.reticleSize >= 20 {
                Circle()
                    .fill(.white)
                    .frame(width: 3, height: 3)
            }
        }
        .shadow(radius: 2)
        .accessibilityHidden(true)
    }

    private var readoutPanel: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(model.color?.color ?? .clear)
                    .strokeBorder(.quaternary, lineWidth: 1)
                    .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 3) {
                    Text(descriptiveName)
                        .font(.title2.bold())
                    Text(basicName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(model.color?.hexString ?? "—")
                        .font(.body.monospaced())
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // La fila del aviso reserva siempre su hueco (si el perfil tiene
            // daltonismo) para que el panel no dé saltos al aparecer.
            if profiles.first?.visionType != .normal {
                Label(
                    confusionWarning.map { String(localized: "Con tu visión podría parecer \($0.lowercased())") } ?? " ",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .singleLineFitted()
                .font(.footnote.weight(.medium))
                .foregroundStyle(.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(confusionWarning == nil ? 0 : 1)
                .animation(.easeInOut(duration: 0.25), value: confusionWarning == nil)
            }

            HStack(spacing: 10) {
                Image(systemName: "smallcircle.filled.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(value: $model.reticleSize, in: 12...60, step: 2)
                    .accessibilityLabel("Tamaño de la mirilla")
                Image(systemName: "smallcircle.filled.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button {
                    model.isFrozen.toggle()
                } label: {
                    Label(
                        model.isFrozen ? "Reanudar" : "Congelar",
                        systemImage: model.isFrozen ? "play.fill" : "pause.fill"
                    )
                    .singleLineFitted()
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    saveCurrentColor()
                } label: {
                    Label(justSaved ? "Guardado" : "Guardar", systemImage: justSaved ? "checkmark" : "square.and.arrow.down")
                        .singleLineFitted()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(model.color == nil || justSaved)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private var basicName: String {
        guard let color = model.color else { return "…" }
        return ColorNamer.basicName(for: color)
    }

    private var descriptiveName: String {
        guard let color = model.color else { return "…" }
        return ColorNamer.descriptiveName(for: color)
    }

    private var confusionWarning: String? {
        guard let color = model.color, let profile = profiles.first else { return nil }
        return ColorNamer.perceivedName(for: color, visionType: profile.visionType)
    }

    private func saveCurrentColor() {
        guard let color = model.color else { return }
        let saved = SavedColor(red: color.red, green: color.green, blue: color.blue)
        modelContext.insert(saved)
        pruneHistoryIfNeeded()
        justSaved = true
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            justSaved = false
        }
    }

    /// El historial gratis se queda en los últimos `freeHistoryLimit`
    /// colores: al superar el límite se borran los más antiguos.
    private func pruneHistoryIfNeeded() {
        guard !purchaseManager.isPremium else { return }
        let overflow = savedColors.count - PurchaseManager.freeHistoryLimit
        guard overflow > 0 else { return }
        for saved in savedColors.prefix(overflow) {
            modelContext.delete(saved)
        }
    }

    // MARK: - Permisos

    private var permissionExplainer: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("El escáner necesita la cámara")
                .font(.title2.bold())
            Text("Apunta a cualquier objeto y te diremos su color al instante. La imagen se procesa en tu iPhone y nunca sale de él.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button {
                Task {
                    await model.requestAccess()
                    model.start()
                }
            } label: {
                Text("Permitir cámara")
                    .singleLineFitted()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
    }

    private var permissionDenied: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "video.slash")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("Sin acceso a la cámara")
                .font(.title2.bold())
            Text("Concede acceso a la cámara en Ajustes para poder escanear colores.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            if let url = URL(string: UIApplication.openSettingsURLString) {
                Link(destination: url) {
                    Text("Abrir Ajustes")
                        .singleLineFitted()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(24)
    }
}

#Preview {
    ScannerView()
        .environment(PurchaseManager())
}
