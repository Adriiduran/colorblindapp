//
//  TestShape.swift
//  colorblindapp
//

import SwiftUI

/// Figura tocable usada en el test infantil, en vez del dígito del test
/// estándar. La misma silueta talla el hueco de la lámina y dibuja el botón
/// de respuesta correspondiente, así el niño reconoce visualmente la forma.
enum TestShape: String, CaseIterable, Identifiable {
    case circle
    case square
    case triangle
    case star
    case heart

    var id: String { rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .circle: "Círculo"
        case .square: "Cuadrado"
        case .triangle: "Triángulo"
        case .star: "Estrella"
        case .heart: "Corazón"
        }
    }

    /// Silueta rellena, centrada y ajustada a `rect`.
    func path(in rect: CGRect) -> Path {
        switch self {
        case .circle:
            return Path(ellipseIn: rect)
        case .square:
            return Path(rect)
        case .triangle:
            return Self.trianglePath(in: rect)
        case .star:
            return Self.starPath(in: rect, points: 5)
        case .heart:
            return Self.heartPath(in: rect)
        }
    }

    private static func trianglePath(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }

    private static func starPath(in rect: CGRect, points: Int) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.4
        let angleStep = Double.pi / Double(points)

        var path = Path()
        for i in 0..<(points * 2) {
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let angle = Double(i) * angleStep - .pi / 2
            let point = CGPoint(
                x: center.x + radius * CGFloat(cos(angle)),
                y: center.y + radius * CGFloat(sin(angle))
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    private static func heartPath(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let start = CGPoint(x: rect.midX, y: rect.minY + height * 0.28)

        path.move(to: start)
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.minY + height * 0.28),
            control1: CGPoint(x: rect.midX - width * 0.1, y: rect.minY),
            control2: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.minX - width * 0.05, y: rect.minY + height * 0.6),
            control2: CGPoint(x: rect.midX, y: rect.minY + height * 0.8)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + height * 0.28),
            control1: CGPoint(x: rect.midX, y: rect.minY + height * 0.8),
            control2: CGPoint(x: rect.maxX + width * 0.05, y: rect.minY + height * 0.6)
        )
        path.addCurve(
            to: start,
            control1: CGPoint(x: rect.maxX, y: rect.minY),
            control2: CGPoint(x: rect.midX + width * 0.1, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}

/// Envoltorio para usar `TestShape.path(in:)` como `Shape` de SwiftUI, p. ej.
/// en los botones de respuesta del test infantil.
struct TestShapeMark: Shape {
    let shape: TestShape

    func path(in rect: CGRect) -> Path {
        shape.path(in: rect)
    }
}

#Preview {
    HStack {
        ForEach(TestShape.allCases) { shape in
            TestShapeMark(shape: shape)
                .frame(width: 44, height: 44)
        }
    }
    .padding()
}
