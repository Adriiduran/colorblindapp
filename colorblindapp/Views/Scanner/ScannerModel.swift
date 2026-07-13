//
//  ScannerModel.swift
//  colorblindapp
//

import AVFoundation
import Observation
import SwiftUI

/// Estado del escáner: permisos de cámara, color suavizado y congelado.
/// En el simulador no hay cámara, así que un modo demo alimenta el mismo
/// pipeline con una secuencia de colores conocidos.
@Observable
final class ScannerModel {
    enum Authorization {
        case undetermined
        case authorized
        case denied
    }

    private(set) var authorization: Authorization = .undetermined
    private(set) var color: LinearRGB?
    var isFrozen = false

    /// Diámetro de la mirilla en puntos. También determina el área real
    /// muestreada del frame (ver CameraColorSampler.regionFraction).
    var reticleSize: Double = 24

    private var sampler: CameraColorSampler?
    private var viewLongSide: Double = 0

    var isDemoMode: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }

    var captureSession: AVCaptureSession? {
        sampler?.session
    }

    func refreshAuthorization() {
        if isDemoMode {
            authorization = .authorized
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: authorization = .authorized
        case .notDetermined: authorization = .undetermined
        default: authorization = .denied
        }
    }

    func requestAccess() async {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        authorization = granted ? .authorized : .denied
    }

    func start() {
        guard authorization == .authorized else { return }
        if isDemoMode {
            startDemo()
            return
        }
        if sampler == nil {
            sampler = CameraColorSampler { [weak self] sample in
                MainActor.assumeIsolated {
                    self?.ingest(sample)
                }
            }
        }
        sampler?.start()
        applySamplingRegion()
    }

    /// El visor mide `longSide` puntos en su dimensión larga; necesario para
    /// convertir el diámetro de la mirilla a fracción del frame.
    func updateViewLongSide(_ longSide: Double) {
        viewLongSide = longSide
        applySamplingRegion()
    }

    func applySamplingRegion() {
        guard viewLongSide > 0 else { return }
        sampler?.setRegionFraction(reticleSize / viewLongSide)
    }

    func stop() {
        sampler?.stop()
        demoTask?.cancel()
        demoTask = nil
    }

    /// Suavizado exponencial: evita que el valor "baile" frame a frame.
    private func ingest(_ sample: LinearRGB) {
        guard !isFrozen else { return }
        if let current = color {
            color = current.mixed(with: sample, amount: 0.3)
        } else {
            color = sample
        }
    }

    // MARK: - Modo demo (solo simulador)

    private var demoTask: Task<Void, Never>?
    private(set) var demoColorIndex = 0

    /// Colores variados para recorrer las categorías del clasificador.
    static let demoColors: [LinearRGB] = [
        LinearRGB(hex: "#6B8E23"), // verde oliva
        LinearRGB(hex: "#C8102E"), // rojo
        LinearRGB(hex: "#1E90FF"), // azul
        LinearRGB(hex: "#F4A460"), // marrón arena
        LinearRGB(hex: "#FFD700"), // amarillo
        LinearRGB(hex: "#8A2BE2"), // morado
        LinearRGB(hex: "#FF69B4"), // rosa
        LinearRGB(hex: "#40E0D0"), // turquesa
        LinearRGB(hex: "#808080"), // gris
        LinearRGB(hex: "#F5F0E6"), // blanco roto
    ]

    private func startDemo() {
        guard demoTask == nil else { return }
        demoTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                if !self.isFrozen {
                    self.demoColorIndex = (self.demoColorIndex + 1) % Self.demoColors.count
                    // Sin suavizado en demo: el color mostrado debe ser el puro.
                    self.color = Self.demoColors[self.demoColorIndex]
                }
                try? await Task.sleep(for: .seconds(1.6))
            }
        }
    }
}
