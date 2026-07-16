//
//  IshiharaPlateView.swift
//  colorblindapp
//

import CoreText
import SwiftUI

/// Qué se talla en la lámina: el dígito del test estándar o la figura del
/// test infantil.
enum PlateFigure: Hashable {
    case digit
    case shape
}

/// Dibuja una lámina pseudo-isocromática: un disco de puntos donde el dígito
/// (o la figura) solo se distingue por tono. Cada punto lleva un jitter de
/// luminancia aleatorio mayor que la diferencia de luminancia figura/fondo,
/// para que el brillo no sirva de pista y el único señal sea el color.
struct IshiharaPlateView: View {
    let plate: TestPlate
    var figure: PlateFigure = .digit

    /// Los puntos son deterministas por lámina + figura (semilla fija), así
    /// que se generan una única vez por combinación y se sirven de caché.
    /// Evita depender de `.task`/estado, que no se dispara fiablemente en
    /// algunas presentaciones.
    private static var dotCache: [String: [PlateDot]] = [:]

    /// Lado del espacio virtual en el que se generan los puntos.
    private static let canvasSide: CGFloat = 360

    private var cacheKey: String { "\(plate.id)-\(figure)" }

    private var dots: [PlateDot] {
        if let cached = Self.dotCache[cacheKey] {
            return cached
        }
        let generated = Self.generateDots(for: plate, figure: figure)
        Self.dotCache[cacheKey] = generated
        return generated
    }

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / Self.canvasSide
            for dot in dots {
                let rect = CGRect(
                    x: (dot.x - dot.radius) * scale,
                    y: (dot.y - dot.radius) * scale,
                    width: dot.radius * 2 * scale,
                    height: dot.radius * 2 * scale
                )
                context.fill(Path(ellipseIn: rect), with: .color(dot.color))
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct PlateDot {
    let x: CGFloat
    let y: CGFloat
    let radius: CGFloat
    let color: Color
}

private extension IshiharaPlateView {
    static func generateDots(for plate: TestPlate, figure: PlateFigure) -> [PlateDot] {
        var rng = SeededGenerator(seed: plate.seed)
        let side = canvasSide
        let plateRadius = side / 2 - 4
        let center = CGPoint(x: side / 2, y: side / 2)
        let figureRect = CGRect(x: side * 0.17, y: side * 0.14, width: side * 0.66, height: side * 0.72)
        let digitPath: Path = switch figure {
        case .digit: Self.digitPath(plate.digit, in: figureRect)
        case .shape: plate.shape.path(in: figureRect)
        }

        let background = LinearRGB(hex: plate.backgroundHex)
        let digitColor = LinearRGB(hex: plate.digitHex)

        var placed: [(x: CGFloat, y: CGFloat, r: CGFloat)] = []
        var dots: [PlateDot] = []

        // Empaquetado por rechazo: radios de mayor a menor para rellenar huecos.
        let passes: [(radius: CGFloat, attempts: Int)] = [
            (11, 250), (8.5, 400), (6.5, 700), (5, 1100), (3.8, 1600),
        ]

        for pass in passes {
            for _ in 0..<pass.attempts {
                let r = pass.radius * CGFloat.random(in: 0.85...1.0, using: &rng)
                let x = CGFloat.random(in: r...(side - r), using: &rng)
                let y = CGFloat.random(in: r...(side - r), using: &rng)

                let dx = x - center.x, dy = y - center.y
                guard (dx * dx + dy * dy).squareRoot() + r <= plateRadius else { continue }
                guard placed.allSatisfy({ other in
                    let ox = other.x - x, oy = other.y - y
                    return (ox * ox + oy * oy).squareRoot() >= other.r + r + 1.6
                }) else { continue }

                // Los puntos que cruzan el borde del dígito se descartan: el
                // hueco resultante perfila la cifra igual que en las láminas reales.
                let samples = [
                    CGPoint(x: x, y: y),
                    CGPoint(x: x + r * 0.8, y: y), CGPoint(x: x - r * 0.8, y: y),
                    CGPoint(x: x, y: y + r * 0.8), CGPoint(x: x, y: y - r * 0.8),
                ]
                let insideFlags = samples.map { digitPath.contains($0) }
                guard insideFlags.dropFirst().allSatisfy({ $0 == insideFlags[0] }) else { continue }

                let base = insideFlags[0] ? digitColor : background
                let jitter = Double.random(in: 0.68...1.32, using: &rng)
                placed.append((x, y, r))
                dots.append(PlateDot(x: x, y: y, radius: r, color: base.scaled(by: jitter).color))
            }
        }
        return dots
    }

    /// Trazado del dígito, ajustado y centrado en `rect`.
    static func digitPath(_ digit: Int, in rect: CGRect) -> Path {
        let font = CTFontCreateWithName("ArialRoundedMTBold" as CFString, 100, nil)
        var chars = Array(String(digit).utf16)
        var glyphs = [CGGlyph](repeating: 0, count: chars.count)
        CTFontGetGlyphsForCharacters(font, &chars, &glyphs, chars.count)
        guard let glyphPath = CTFontCreatePathForGlyph(font, glyphs[0], nil) else {
            return Path()
        }

        let bounds = glyphPath.boundingBox
        let scale = min(rect.width / bounds.width, rect.height / bounds.height)
        var transform = CGAffineTransform.identity
            .translatedBy(x: rect.midX, y: rect.midY)
            .scaledBy(x: scale, y: -scale) // el espacio de la fuente tiene la Y invertida
            .translatedBy(x: -bounds.midX, y: -bounds.midY)
        guard let fitted = glyphPath.copy(using: &transform) else {
            return Path()
        }
        return Path(fitted)
    }
}

#Preview {
    VStack {
        ForEach(ColorVisionTest.plates.prefix(2)) { plate in
            IshiharaPlateView(plate: plate)
                .padding()
        }
    }
}
