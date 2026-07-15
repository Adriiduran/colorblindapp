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
/// dominantes con k-means en espacio Lab. Todo corre fuera del hilo principal.
nonisolated enum GarmentAnalyzer {
    struct Analysis: Sendable {
        /// PNG de la prenda recortada, con transparencia.
        let croppedImagePNG: Data
        let dominant: LinearRGB
        /// Hasta 2 colores alternativos plausibles detectados en la misma
        /// foto, para corregir con un toque en la revisión si el algoritmo
        /// se equivocó de color.
        let candidates: [LinearRGB]
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
        let segmentation = subjectSegmentation(from: cgImage)
        let cropped = segmentation?.croppedMasked ?? cgImage
        let illuminant = segmentation.flatMap { estimateIlluminant(fullImage: cgImage, maskBuffer: $0.maskBuffer) }

        let clusters = dominantColors(in: cropped, illuminant: illuminant)
        guard let first = clusters.first else {
            throw AnalysisError.noColorsFound
        }
        let rest = clusters.dropFirst()
        // Un secundario solo cuenta si tiene peso real y se distingue del
        // dominante (prendas bicolor o estampadas).
        let secondary = rest.first { candidate in
            candidate.weight > 0.18 && candidate.color.deltaE(to: first.color) > 22
        }
        // Candidatos para corrección de un toque: otros clusters presentes
        // en la foto que se distinguen a ojo del dominante elegido.
        let candidates = rest
            .filter { $0.color.deltaE(to: first.color) > 12 }
            .prefix(2)
            .map(\.color)

        guard let png = UIImage(cgImage: cropped).pngData() else {
            throw AnalysisError.invalidImage
        }
        return Analysis(
            croppedImagePNG: png,
            dominant: first.color,
            candidates: Array(candidates),
            secondary: secondary?.color
        )
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

    private struct Segmentation {
        /// Prenda recortada y compuesta sobre transparencia (fondo fuera).
        let croppedMasked: CGImage
        /// Máscara a tamaño completo (misma resolución que la imagen
        /// normalizada), para poder muestrear el fondo por separado.
        let maskBuffer: CVPixelBuffer
    }

    private static func subjectSegmentation(from cgImage: CGImage) -> Segmentation? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage)
        guard (try? handler.perform([request])) != nil,
              let result = request.results?.first,
              let maskedBuffer = try? result.generateMaskedImage(
                  ofInstances: result.allInstances,
                  from: handler,
                  croppedToInstancesExtent: true
              ),
              let maskBuffer = try? result.generateScaledMaskForImage(
                  forInstances: result.allInstances,
                  from: handler
              )
        else {
            return nil
        }

        let ciImage = CIImage(cvPixelBuffer: maskedBuffer)
        guard let cropped = CIContext().createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return Segmentation(croppedMasked: cropped, maskBuffer: maskBuffer)
    }

    // MARK: - Balance de blancos

    /// Estima el iluminante de la escena a partir del fondo (los píxeles
    /// fuera de la máscara de la prenda) para poder corregir tintes de luz
    /// ambiente (p. ej. luz cálida de interior). Devuelve `nil` si hay poco
    /// fondo visible o si el fondo no es razonablemente neutro — en ese caso
    /// es más probable que sea un fondo de color que luz tiñendo un fondo
    /// liso, y corregir sería contraproducente.
    private static func estimateIlluminant(fullImage: CGImage, maskBuffer: CVPixelBuffer) -> LinearRGB? {
        let maskCI = CIImage(cvPixelBuffer: maskBuffer)
        let inverted = maskCI.applyingFilter("CIColorInvert")
        let fullCI = CIImage(cgImage: fullImage)
        let backgroundOnly = fullCI.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputMaskImageKey: inverted,
            kCIInputBackgroundImageKey: CIImage(color: .clear).cropped(to: fullCI.extent),
        ])
        guard let backgroundCG = CIContext().createCGImage(backgroundOnly, from: fullCI.extent),
              let pixels = rawPixels(from: backgroundCG, side: 96)
        else {
            return nil
        }

        var sumR = 0.0, sumG = 0.0, sumB = 0.0
        var count = 0
        for i in pixels.colors.indices where pixels.alphas[i] > 128 {
            let color = pixels.colors[i]
            sumR += color.red
            sumG += color.green
            sumB += color.blue
            count += 1
        }
        guard count > 200 else { return nil }
        let avg = LinearRGB(red: sumR / Double(count), green: sumG / Double(count), blue: sumB / Double(count))

        let lab = avg.lab
        let chroma = (lab.a * lab.a + lab.b * lab.b).squareRoot()
        guard chroma < 25 else { return nil }
        return avg
    }

    /// Corrección de balance de blancos por "white patch": escala cada
    /// canal para que el fondo (que se asume neutro) se acerque al gris,
    /// preservando su luminancia media. Deliberadamente conservadora — solo
    /// recorre la mitad del camino hacia la corrección ideal y acota el
    /// factor — porque la estimación del iluminante es ruidosa.
    private static func whiteBalanced(_ samples: [LinearRGB], illuminant: LinearRGB?) -> [LinearRGB] {
        guard let illuminant else { return samples }
        let gray = (illuminant.red + illuminant.green + illuminant.blue) / 3
        guard gray > 0.001 else { return samples }

        func factor(_ channel: Double) -> Double {
            guard channel > 0.001 else { return 1 }
            let ideal = gray / channel
            let conservative = 1 + 0.5 * (ideal - 1)
            return min(max(conservative, 0.75), 1.35)
        }
        let fr = factor(illuminant.red), fg = factor(illuminant.green), fb = factor(illuminant.blue)
        return samples.map { LinearRGB(red: $0.red * fr, green: $0.green * fg, blue: $0.blue * fb) }
    }

    // MARK: - Color dominante (k-means en Lab)

    private static func dominantColors(in cgImage: CGImage, illuminant: LinearRGB?) -> [(color: LinearRGB, weight: Double)] {
        guard let rawSamples = colorSamples(from: cgImage), !rawSamples.isEmpty else { return [] }
        let balanced = whiteBalanced(rawSamples, illuminant: illuminant)
        let samples = discardingShadowsAndHighlights(from: balanced)
        guard !samples.isEmpty else { return [] }

        let labs = samples.map(\.lab)
        let k = min(4, labs.count)
        let sortedIndices = labs.indices.sorted { labs[$0].l < labs[$1].l }
        var centroids: [(l: Double, a: Double, b: Double)] = (0..<k)
            .map { labs[sortedIndices[(sortedIndices.count - 1) * $0 / max(k - 1, 1)]] }
        var assignments = [Int](repeating: 0, count: labs.count)

        for _ in 0..<12 {
            for (i, lab) in labs.enumerated() {
                var best = 0
                var bestDistance = Double.infinity
                for (j, centroid) in centroids.enumerated() {
                    let dl = lab.l - centroid.l
                    let da = lab.a - centroid.a
                    let db = lab.b - centroid.b
                    let distance = dl * dl + da * da + db * db
                    if distance < bestDistance {
                        bestDistance = distance
                        best = j
                    }
                }
                assignments[i] = best
            }
            for j in 0..<k {
                let members = labs.indices.filter { assignments[$0] == j }
                guard !members.isEmpty else { continue }
                let count = Double(members.count)
                centroids[j] = (
                    members.reduce(0) { $0 + labs[$1].l } / count,
                    members.reduce(0) { $0 + labs[$1].a } / count,
                    members.reduce(0) { $0 + labs[$1].b } / count
                )
            }
        }

        let total = Double(labs.count)
        let clusters: [(color: LinearRGB, weight: Double, chroma: Double, lightness: Double)] = (0..<k).compactMap { j in
            let members = labs.indices.filter { assignments[$0] == j }
            guard !members.isEmpty else { return nil }
            let weight = Double(members.count) / total
            guard weight > 0.02 else { return nil }

            // Mediana por canal en Lab, no la media: robusta frente a
            // outliers (un pliegue o un reflejo puntual que sobreviva al
            // filtrado no puede arrastrar el color reportado).
            let medianL = median(members.map { labs[$0].l })
            let medianA = median(members.map { labs[$0].a })
            let medianB = median(members.map { labs[$0].b })
            let color = LinearRGB.fromLab(l: medianL, a: medianA, b: medianB)
            let chroma = (medianA * medianA + medianB * medianB).squareRoot()
            return (color, weight, chroma, medianL)
        }

        // Si ningún cluster conserva croma real, la prenda es gris/negra/
        // blanca de verdad: elegir solo por peso. Si alguno sí, elegir por
        // peso×croma para que un pliegue o sombra grande y apagada no gane
        // sobre el color real de la prenda por pura mayoría de píxeles.
        let hasChroma = clusters.contains { $0.chroma >= 8 }
        let ranked: [(color: LinearRGB, weight: Double, chroma: Double, lightness: Double)]
        if hasChroma {
            ranked = clusters.sorted { $0.weight * $0.chroma > $1.weight * $1.chroma }
        } else {
            // Prendas negras de tejido acanalado (pana, punto grueso...)
            // reflejan tanta luz en las crestas que el brillo especular
            // puede cubrir más píxeles que el propio tejido oscuro. Si hay
            // un modo oscuro sustancial, tratamos los clusters muy claros
            // como brillo y no como el color real, aunque pesen más.
            let hasDarkMode = clusters.contains { $0.lightness < 35 && $0.weight >= 0.15 }
            let candidates = hasDarkMode ? clusters.filter { $0.lightness < 88 } : clusters
            ranked = (candidates.isEmpty ? clusters : candidates).sorted { $0.weight > $1.weight }
        }

        return ranked.map { (color: $0.color, weight: $0.weight) }
    }

    private static func median(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        let mid = sorted.count / 2
        return sorted.count % 2 == 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]
    }

    /// Descarta los píxeles en sombra y los brillos especulares cuando la
    /// prenda tiene color real.
    ///
    /// En una prenda arrugada u oscura las sombras del propio tejido son
    /// píxeles oscuros y sin croma que pueden ser mayoría, y un reflejo
    /// especular sobre tela saturada es un píxel claro y sin croma que
    /// arrastra el dominante hacia el blanco: en ambos casos el k-means
    /// podría elegirlos como dominante y un pantalón caqui saldría "gris".
    /// Si al menos un cuarto de los píxeles conserva croma (el tinte es
    /// visible en la foto), los píxeles oscuros y los muy claros sin croma
    /// se tratan como sombra/brillo y no participan en el análisis. Si nada
    /// tiene croma (prenda negra, gris o blanca de verdad), se dejan todos.
    private static func discardingShadowsAndHighlights(from samples: [LinearRGB]) -> [LinearRGB] {
        // Mismo umbral de croma que separa "Gris" del resto en ColorNamer.
        let chromaThreshold = 8.0
        let labs = samples.map(\.lab)
        func chroma(_ lab: (l: Double, a: Double, b: Double)) -> Double {
            (lab.a * lab.a + lab.b * lab.b).squareRoot()
        }

        let chromaticCount = labs.count(where: { chroma($0) >= chromaThreshold })
        guard Double(chromaticCount) >= 0.25 * Double(samples.count) else { return samples }

        let lit = zip(samples, labs)
            .filter { pair in
                let c = chroma(pair.1)
                let isShadow = c < chromaThreshold && pair.1.l < 35
                let isSpecular = c < chromaThreshold && pair.1.l > 88
                return !isShadow && !isSpecular
            }
            .map(\.0)
        return lit.isEmpty ? samples : lit
    }

    // MARK: - Muestreo de píxeles

    /// Reduce la imagen a una rejilla y devuelve los píxeles útiles del
    /// interior de la prenda: erosiona la máscara de transparencia unos
    /// píxeles para descartar el halo de borde (donde Vision mezcla la
    /// prenda con el fondo al recortar) y descarta casi blancos (fondo sin
    /// recortar, cuando Vision no encontró sujeto).
    private static func colorSamples(from cgImage: CGImage, side: Int = 192, erosionRadius: Int = 2) -> [LinearRGB]? {
        guard let pixels = rawPixels(from: cgImage, side: side) else { return nil }
        let mask = pixels.alphas.map { $0 > 128 }
        let eroded = erode(mask, side: side, radius: erosionRadius)

        var samples: [LinearRGB] = []
        samples.reserveCapacity(side * side)
        for i in 0..<(side * side) where eroded[i] {
            let color = pixels.colors[i]
            let (r, g, b) = color.srgbComponents
            let maxC = max(r, g, b), minC = min(r, g, b)
            let lightness = (maxC + minC) / 2
            let isNearWhite = lightness > 0.92 && (maxC - minC) < 0.08
            if !isNearWhite {
                samples.append(color)
            }
        }
        // Si la erosión se comió toda la máscara (prenda muy fina o
        // recorte diminuto), es mejor un resultado con halo que ninguno.
        return samples.isEmpty ? colorSamplesWithoutErosion(pixels: pixels, side: side) : samples
    }

    private static func colorSamplesWithoutErosion(pixels: (colors: [LinearRGB], alphas: [UInt8]), side: Int) -> [LinearRGB] {
        var samples: [LinearRGB] = []
        for i in 0..<(side * side) where pixels.alphas[i] > 128 {
            let color = pixels.colors[i]
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

    /// Erosiona una máscara booleana: un píxel sobrevive solo si todos sus
    /// vecinos en el radio dado también están dentro de la máscara.
    private static func erode(_ mask: [Bool], side: Int, radius: Int) -> [Bool] {
        guard radius > 0 else { return mask }
        var result = [Bool](repeating: false, count: mask.count)
        for y in 0..<side {
            for x in 0..<side {
                let i = y * side + x
                guard mask[i] else { continue }
                var keep = true
                outer: for dy in -radius...radius {
                    let ny = y + dy
                    guard ny >= 0, ny < side else { keep = false; break outer }
                    for dx in -radius...radius {
                        let nx = x + dx
                        guard nx >= 0, nx < side, mask[ny * side + nx] else {
                            keep = false
                            break outer
                        }
                    }
                }
                result[i] = keep
            }
        }
        return result
    }

    /// Dibuja la imagen en una rejilla `side`×`side` y devuelve el color
    /// (deshaciendo la premultiplicación) y el alfa de cada celda.
    private static func rawPixels(from cgImage: CGImage, side: Int) -> (colors: [LinearRGB], alphas: [UInt8])? {
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
        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: side, height: side))
        guard let data = context.data else { return nil }

        let buffer = data.assumingMemoryBound(to: UInt8.self)
        var colors = [LinearRGB](repeating: LinearRGB(red: 0, green: 0, blue: 0), count: side * side)
        var alphas = [UInt8](repeating: 0, count: side * side)

        for i in 0..<(side * side) {
            let offset = i * 4
            let alpha = buffer[offset + 3]
            alphas[i] = alpha
            guard alpha > 128 else { continue }

            let a = Double(alpha) / 255
            colors[i] = LinearRGB(
                srgbRed: Double(buffer[offset]) / 255 / a,
                srgbGreen: Double(buffer[offset + 1]) / 255 / a,
                srgbBlue: Double(buffer[offset + 2]) / 255 / a
            )
        }
        return (colors, alphas)
    }
}

#if DEBUG
/// Banco de pruebas interno para medir la fiabilidad del extractor de color
/// sin depender de fotos reales (no hay dataset fotográfico en el repo).
/// Construye escenas sintéticas de 192×192 —la misma resolución que usa
/// `colorSamples`— con sombra, brillo especular, halo de borde y tinte de
/// iluminante inyectados a propósito, y comprueba que `dominantColors`
/// sigue recuperando el color y la categoría correctos. No sustituye a un
/// benchmark con fotos reales etiquetadas (mejora natural cuando exista ese
/// dataset), pero valida que cada mejora del pipeline hace lo que dice.
extension GarmentAnalyzer {
    enum Benchmark {
        struct Result: Identifiable, Sendable {
            let id = UUID()
            let name: String
            let expectedHex: String
            let gotHex: String
            let expectedBasic: String
            let gotBasic: String
            let deltaE: Double
            var passed: Bool { expectedBasic == gotBasic }
        }

        static func run() -> [Result] {
            cases.map { testCase in
                let clusters = dominantColors(in: testCase.image, illuminant: testCase.illuminant)
                let got = clusters.first?.color ?? LinearRGB(red: 0, green: 0, blue: 0)
                return Result(
                    name: testCase.name,
                    expectedHex: testCase.expected.hexString,
                    gotHex: got.hexString,
                    expectedBasic: ColorNamer.basicName(for: testCase.expected),
                    gotBasic: ColorNamer.basicName(for: got),
                    deltaE: got.deltaE(to: testCase.expected)
                )
            }
        }

        // MARK: - Casos sintéticos

        private static var cases: [(name: String, image: CGImage, illuminant: LinearRGB?, expected: LinearRGB)] {
            let red = LinearRGB(hex: "#C0392B")
            let khaki = LinearRGB(hex: "#6E6B3A")
            let blue = LinearRGB(hex: "#1F4E8C")
            let green = LinearRGB(hex: "#3F7D4A")
            let black = LinearRGB(hex: "#0A0A0A")
            let backgroundGray = LinearRGB(hex: "#D9D9D9")

            // Tinte cálido (~tungsteno) aplicado en RGB lineal: es el mismo
            // modelo de ganancia por canal que corrige `whiteBalanced`, así
            // que este caso valida la fórmula de corrección en sí, no una
            // fotografía real bajo luz cálida.
            let skyBlue = LinearRGB(hex: "#3B6FB5")
            let cast = LinearRGB(red: 1.18, green: 1.03, blue: 0.78)
            let tintedSkyBlue = LinearRGB(red: skyBlue.red * cast.red, green: skyBlue.green * cast.green, blue: skyBlue.blue * cast.blue)
            let illuminantEstimate = LinearRGB(red: 0.5 * cast.red, green: 0.5 * cast.green, blue: 0.5 * cast.blue)

            return [
                (
                    "Rojo liso, sin ruido",
                    scene(garment: red),
                    nil,
                    red
                ),
                (
                    "Caqui oscuro con sombra de pliegues",
                    scene(garment: khaki, shadowFraction: 0.4),
                    nil,
                    khaki
                ),
                (
                    "Azul con brillo especular",
                    scene(garment: blue, highlightFraction: 0.15),
                    nil,
                    blue
                ),
                (
                    "Verde con halo de borde mezclado con el fondo",
                    scene(garment: green, haloBlendWith: backgroundGray, haloWidth: 2),
                    nil,
                    green
                ),
                (
                    "Azul bajo tinte cálido (balance de blancos)",
                    scene(garment: tintedSkyBlue),
                    illuminantEstimate,
                    skyBlue
                ),
                (
                    "Negro real, sin croma",
                    scene(garment: black),
                    nil,
                    black
                ),
            ]
        }

        /// Dibuja una escena de 192×192: la prenda ocupa un cuadrado
        /// centrado (opaco) sobre fondo transparente. `haloBlendWith`
        /// simula el borde mezclado que deja Vision al recortar; `shadow`/
        /// `highlightFraction` simulan sombra de pliegues y reflejo
        /// especular dentro de la prenda.
        private static func scene(
            garment: LinearRGB,
            haloBlendWith: LinearRGB? = nil,
            haloWidth: CGFloat = 0,
            shadowFraction: CGFloat = 0,
            highlightFraction: CGFloat = 0
        ) -> CGImage {
            let side = 192
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            format.opaque = false
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
            let image = renderer.image { ctx in
                let cg = ctx.cgContext
                let inset: CGFloat = 24
                let outer = CGRect(x: inset, y: inset, width: CGFloat(side) - inset * 2, height: CGFloat(side) - inset * 2)

                if let haloBlendWith {
                    let blended = garment.mixed(with: haloBlendWith, amount: 0.5)
                    cg.setFillColor(uiColor(blended).cgColor)
                    cg.fill(outer)
                }

                let inner = haloBlendWith != nil ? outer.insetBy(dx: haloWidth, dy: haloWidth) : outer
                cg.setFillColor(uiColor(garment).cgColor)
                cg.fill(inner)

                if shadowFraction > 0 {
                    let shadowHeight = inner.height * shadowFraction
                    let shadowRect = CGRect(x: inner.minX, y: inner.maxY - shadowHeight, width: inner.width, height: shadowHeight)
                    cg.setFillColor(UIColor(white: 0.08, alpha: 1).cgColor)
                    cg.fill(shadowRect)
                }

                if highlightFraction > 0 {
                    let r = inner.width * CGFloat(highlightFraction).squareRoot() / 2
                    let center = CGPoint(x: inner.minX + inner.width * 0.3, y: inner.minY + inner.height * 0.3)
                    cg.setFillColor(UIColor(white: 0.97, alpha: 1).cgColor)
                    cg.fillEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
                }
            }
            return image.cgImage!
        }

        private static func uiColor(_ color: LinearRGB) -> UIColor {
            let (r, g, b) = color.srgbComponents
            return UIColor(red: r, green: g, blue: b, alpha: 1)
        }
    }
}
#endif
