//
//  LinearRGB.swift
//  colorblindapp
//

import SwiftUI

/// Color en espacio RGB lineal. Las láminas del test trabajan en lineal
/// porque los pares de confusión y el jitter de luminancia solo son
/// correctos ahí, no en sRGB.
/// `nonisolated`: es un tipo de valor puro que también se usa desde la cola
/// de captura de la cámara.
nonisolated struct LinearRGB {
    var red: Double
    var green: Double
    var blue: Double

    init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    /// Crea el color desde un hex sRGB tipo "#C8783C".
    init(hex: String) {
        var value: UInt64 = 0
        Scanner(string: hex.replacingOccurrences(of: "#", with: "")).scanHexInt64(&value)
        func lin(_ byte: UInt64) -> Double {
            let s = Double(byte) / 255
            return s <= 0.04045 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4)
        }
        self.init(red: lin((value >> 16) & 0xFF), green: lin((value >> 8) & 0xFF), blue: lin(value & 0xFF))
    }

    /// Crea el color desde componentes sRGB en rango 0...1.
    init(srgbRed: Double, srgbGreen: Double, srgbBlue: Double) {
        func lin(_ s: Double) -> Double {
            s <= 0.04045 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4)
        }
        self.init(red: lin(srgbRed), green: lin(srgbGreen), blue: lin(srgbBlue))
    }

    /// Escala la luminancia; usado para el jitter por punto de las láminas.
    func scaled(by factor: Double) -> LinearRGB {
        LinearRGB(red: red * factor, green: green * factor, blue: blue * factor)
    }

    /// Mezcla hacia `other`; usado para el suavizado temporal del escáner.
    func mixed(with other: LinearRGB, amount: Double) -> LinearRGB {
        LinearRGB(
            red: red + (other.red - red) * amount,
            green: green + (other.green - green) * amount,
            blue: blue + (other.blue - blue) * amount
        )
    }

    /// Componentes sRGB en rango 0...1.
    var srgbComponents: (red: Double, green: Double, blue: Double) {
        func srgb(_ v: Double) -> Double {
            let c = min(max(v, 0), 1)
            return c <= 0.0031308 ? c * 12.92 : 1.055 * pow(c, 1 / 2.4) - 0.055
        }
        return (srgb(red), srgb(green), srgb(blue))
    }

    /// Representación hexadecimal sRGB, p. ej. "#6B8E23".
    var hexString: String {
        let (r, g, b) = srgbComponents
        return String(
            format: "#%02X%02X%02X",
            Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded())
        )
    }

    var color: Color {
        func srgb(_ v: Double) -> Double {
            let c = min(max(v, 0), 1)
            return c <= 0.0031308 ? c * 12.92 : 1.055 * pow(c, 1 / 2.4) - 0.055
        }
        return Color(.sRGB, red: srgb(red), green: srgb(green), blue: srgb(blue))
    }
}

/// Generador determinista (SplitMix64) para que cada lámina se dibuje
/// siempre igual a partir de su semilla.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
