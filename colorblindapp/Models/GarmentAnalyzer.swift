//
//  GarmentAnalyzer.swift
//  colorblindapp
//

import CoreImage
import Foundation
import UIKit
import Vision

/// Procesa la foto de una prenda: aísla la prenda del fondo con Vision
/// (el mismo motor de "levantar sujeto" de Fotos) y extrae sus colores
/// dominantes con k-means. Todo corre fuera del hilo principal.
nonisolated enum GarmentAnalyzer {
    struct Analysis: Sendable {
        /// PNG de la prenda recortada, con transparencia.
        let croppedImagePNG: Data
        let dominant: LinearRGB
        let secondary: LinearRGB?
    }

    enum AnalysisError: LocalizedError {
        case invalidImage
        case noColorsFound

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                String(localized: "No se pudo leer la imagen.")
            case .noColorsFound:
                String(localized: "No se pudo detectar el color de la prenda. Prueba con una foto sobre fondo liso y con buena luz.")
            }
        }
    }

    static func analyze(imageData: Data) async throws -> Analysis {
        guard let normalized = normalizedImage(from: imageData),
              let cgImage = normalized.cgImage else {
            throw AnalysisError.invalidImage
        }

        // Recorte del sujeto. Si Vision no encuentra sujeto (foto plana,
        // simulador sin soporte…), seguimos con la imagen completa: el
        // filtro de fondos claros del k-means suele bastar.
        let cropped = subjectImage(from: cgImage) ?? cgImage

        let clusters = dominantColors(in: cropped)
        guard let first = clusters.first else {
            throw AnalysisError.noColorsFound
        }
        // Un secundario solo cuenta si tiene peso real y se distingue del
        // dominante (prendas bicolor o estampadas).
        let secondary = clusters.dropFirst().first { candidate in
            candidate.weight > 0.18 && candidate.color.deltaE(to: first.color) > 22
        }

        guard let png = UIImage(cgImage: cropped).pngData() else {
            throw AnalysisError.invalidImage
        }
        return Analysis(croppedImagePNG: png, dominant: first.color, secondary: secondary?.color)
    }

    // MARK: - Normalización

    /// Aplica la orientación EXIF y limita el tamaño (el análisis no
    /// necesita más resolución y Vision va mucho más rápido).
    private static func normalizedImage(from data: Data, maxSide: CGFloat = 1200) -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - Recorte con Vision

    private static func subjectImage(from cgImage: CGImage) -> CGImage? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage)
        guard (try? handler.perform([request])) != nil,
              let result = request.results?.first,
              let buffer = try? result.generateMaskedImage(
                  ofInstances: result.allInstances,
                  from: handler,
                  croppedToInstancesExtent: true
              )
        else {
            return nil
        }

        let ciImage = CIImage(cvPixelBuffer: buffer)
        return CIContext().createCGImage(ciImage, from: ciImage.extent)
    }

    // MARK: - Color dominante (k-means)

    private static func dominantColors(in cgImage: CGImage) -> [(color: LinearRGB, weight: Double)] {
        guard let allSamples = colorSamples(from: cgImage), !allSamples.isEmpty else { return [] }
        let samples = discardingShadows(from: allSamples)

        // k-means con k=4 e inicialización determinista (percentiles por luminancia).
        let k = min(4, samples.count)
        let sorted = samples.sorted { ($0.red + $0.green + $0.blue) < ($1.red + $1.green + $1.blue) }
        var centroids: [LinearRGB] = (0..<k).map { sorted[(sorted.count - 1) * $0 / max(k - 1, 1)] }
        var assignments = [Int](repeating: 0, count: samples.count)

        for _ in 0..<12 {
            for (i, sample) in samples.enumerated() {
                var best = 0
                var bestDistance = Double.infinity
                for (j, centroid) in centroids.enumerated() {
                    let dr = sample.red - centroid.red
                    let dg = sample.green - centroid.green
                    let db = sample.blue - centroid.blue
                    let distance = dr * dr + dg * dg + db * db
                    if distance < bestDistance {
                        bestDistance = distance
                        best = j
                    }
                }
                assignments[i] = best
            }
            for j in 0..<k {
                let members = samples.indices.filter { assignments[$0] == j }
                guard !members.isEmpty else { continue }
                let count = Double(members.count)
                centroids[j] = LinearRGB(
                    red: members.reduce(0) { $0 + samples[$1].red } / count,
                    green: members.reduce(0) { $0 + samples[$1].green } / count,
                    blue: members.reduce(0) { $0 + samples[$1].blue } / count
                )
            }
        }

        let total = Double(samples.count)
        return (0..<k)
            .map { j in
                let count = assignments.count(where: { $0 == j })
                return (color: centroids[j], weight: Double(count) / total)
            }
            .filter { $0.weight > 0.02 }
            .sorted { $0.weight > $1.weight }
    }

    /// Descarta los píxeles en sombra cuando la prenda tiene color real.
    ///
    /// En una prenda arrugada u oscura las sombras del propio tejido son
    /// píxeles oscuros y sin croma que pueden ser mayoría, y entonces el
    /// k-means los elige como dominante: un pantalón caqui saldría "gris".
    /// Si al menos un cuarto de los píxeles conserva croma (el tinte es
    /// visible en la foto), los píxeles oscuros y acromáticos se tratan
    /// como sombra y no participan en el análisis. Si nada tiene croma
    /// (prenda negra, gris o blanca de verdad), se dejan todos.
    private static func discardingShadows(from samples: [LinearRGB]) -> [LinearRGB] {
        // Mismo umbral de croma que separa "Gris" del resto en ColorNamer.
        let chromaThreshold = 8.0
        let labs = samples.map(\.lab)
        func chroma(_ lab: (l: Double, a: Double, b: Double)) -> Double {
            (lab.a * lab.a + lab.b * lab.b).squareRoot()
        }

        let chromaticCount = labs.count(where: { chroma($0) >= chromaThreshold })
        guard Double(chromaticCount) >= 0.25 * Double(samples.count) else { return samples }

        let lit = zip(samples, labs)
            .filter { !(chroma($0.1) < chromaThreshold && $0.1.l < 35) }
            .map(\.0)
        return lit.isEmpty ? samples : lit
    }

    /// Reduce la imagen a 64x64 y devuelve los píxeles útiles: descarta
    /// transparentes (fondo recortado) y casi blancos (fondo sin recortar).
    private static func colorSamples(from cgImage: CGImage) -> [LinearRGB]? {
        let side = 64
        guard let context = CGContext(
            data: nil,
            width: side,
            height: side,
            bitsPerComponent: 8,
            bytesPerRow: side * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        context.interpolationQuality = .medium
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: side, height: side))
        guard let data = context.data else { return nil }

        let buffer = data.assumingMemoryBound(to: UInt8.self)
        var samples: [LinearRGB] = []
        samples.reserveCapacity(side * side)

        for i in 0..<(side * side) {
            let offset = i * 4
            let alpha = buffer[offset + 3]
            guard alpha > 128 else { continue }

            let a = Double(alpha) / 255
            // Deshacer la premultiplicación del alfa.
            let color = LinearRGB(
                srgbRed: Double(buffer[offset]) / 255 / a,
                srgbGreen: Double(buffer[offset + 1]) / 255 / a,
                srgbBlue: Double(buffer[offset + 2]) / 255 / a
            )

            let (r, g, b) = color.srgbComponents
            let maxC = max(r, g, b), minC = min(r, g, b)
            let lightness = (maxC + minC) / 2
            let isNearWhite = lightness > 0.92 && (maxC - minC) < 0.08
            if !isNearWhite {
                samples.append(color)
            }
        }
        return samples
    }
}
