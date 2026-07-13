//
//  ScannerView.swift
//  colorblindapp
//

import SwiftUI

/// Escáner de color: apunta la cámara y muestra el color del centro en
/// tres formas (hex, básico y descriptivo — este último llega en el hito 4).
struct ScannerView: View {
    @State private var model = ScannerModel()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Escáner")
                .toolbarVisibility(model.authorization == .authorized ? .hidden : .automatic, for: .navigationBar)
        }
        .onAppear {
            model.refreshAuthorization()
            model.start()
        }
        .onDisappear {
            model.stop()
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
        ZStack {
            viewfinder
                .ignoresSafeArea(edges: .top)

            reticle

            VStack {
                Spacer()
                readoutPanel
            }
        }
    }

    @ViewBuilder
    private var viewfinder: some View {
        if model.isDemoMode {
            // En el simulador no hay cámara: el "mundo" es el propio color demo.
            Rectangle()
                .fill(model.color?.color ?? .black)
                .overlay(alignment: .topTrailing) {
                    Text("MODO DEMO")
                        .font(.caption2.bold())
                        .padding(6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding()
                        .padding(.top, 44) // bajo la barra de estado
                }
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
                .stroke(.white, lineWidth: 2)
                .frame(width: 34, height: 34)
            Circle()
                .stroke(.black.opacity(0.4), lineWidth: 1)
                .frame(width: 37, height: 37)
            Circle()
                .fill(.white)
                .frame(width: 3, height: 3)
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
                    Text(basicName)
                        .font(.title2.bold())
                    Text(model.color?.hexString ?? "—")
                        .font(.body.monospaced())
                        .foregroundStyle(.secondary)
                    Text("Nombre detallado: próximamente")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }

                Spacer()
            }

            Button {
                model.isFrozen.toggle()
            } label: {
                Label(
                    model.isFrozen ? "Reanudar" : "Congelar",
                    systemImage: model.isFrozen ? "play.fill" : "pause.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
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
}
