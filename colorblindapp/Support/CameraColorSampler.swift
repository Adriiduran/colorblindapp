//
//  CameraColorSampler.swift
//  colorblindapp
//

import AVFoundation
import Foundation

/// Captura vídeo de la cámara trasera y muestrea el color medio de una
/// región pequeña en el centro de cada frame. El delegate de AVFoundation
/// corre en una cola en segundo plano; el resultado se publica en main.
final class CameraColorSampler: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated let session = AVCaptureSession()

    private let sampleQueue = DispatchQueue(label: "com.admist.colorblindapp.camera")
    private let onSample: @Sendable (LinearRGB) -> Void

    /// Lado (en píxeles) de la región central que se promedia.
    private nonisolated static let regionSide = 12

    init(onSample: @escaping @Sendable (LinearRGB) -> Void) {
        self.onSample = onSample
        super.init()
        configureSession()
    }

    func start() {
        sampleQueue.async { [session] in
            if !session.isRunning {
                session.startRunning()
            }
        }
    }

    func stop() {
        sampleQueue.async { [session] in
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            return
        }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: sampleQueue)
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
    }

    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        let side = min(Self.regionSide, width, height)
        let originX = (width - side) / 2
        let originY = (height - side) / 2

        var sumR = 0.0, sumG = 0.0, sumB = 0.0
        let buffer = base.assumingMemoryBound(to: UInt8.self)
        for y in originY..<(originY + side) {
            for x in originX..<(originX + side) {
                let offset = y * bytesPerRow + x * 4 // BGRA
                sumB += Double(buffer[offset])
                sumG += Double(buffer[offset + 1])
                sumR += Double(buffer[offset + 2])
            }
        }

        let count = Double(side * side) * 255
        let color = LinearRGB(srgbRed: sumR / count, srgbGreen: sumG / count, srgbBlue: sumB / count)
        let callback = onSample
        DispatchQueue.main.async {
            callback(color)
        }
    }
}
