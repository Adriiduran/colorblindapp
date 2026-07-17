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

    /// Coordenadas CIELAB (D65). Es el espacio perceptualmente uniforme
    /// donde tiene sentido medir distancias entre colores.
    var lab: (l: Double, a: Double, b: Double) {
        // RGB lineal -> XYZ (sRGB, D65)
        let x = 0.4124564 * red + 0.3575761 * green + 0.1804375 * blue
        let y = 0.2126729 * red + 0.7151522 * green + 0.0721750 * blue
        let z = 0.0193339 * red + 0.1191920 * green + 0.9503041 * blue

        func f(_ t: Double) -> Double {
            t > 0.008856 ? pow(t, 1.0 / 3.0) : (7.787 * t + 16.0 / 116.0)
        }
        // Blanco de referencia D65
        let fx = f(x / 0.95047), fy = f(y), fz = f(z / 1.08883)
        return (116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz))
    }

    /// Tono (0-360°), saturación y luminosidad HSL sobre sRGB. Es la base de
    /// la clasificación en categorías básicas y de las reglas de combinación
    /// del generador de outfits.
    var hsl: (hue: Double, saturation: Double, lightness: Double) {
        let (r, g, b) = srgbComponents
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC
        let lightness = (maxC + minC) / 2
        let saturation = delta == 0 ? 0 : delta / (1 - abs(2 * lightness - 1))

        var hue = 0.0
        if delta > 0 {
            switch maxC {
            case r: hue = ((g - b) / delta).truncatingRemainder(dividingBy: 6)
            case g: hue = (b - r) / delta + 2
            default: hue = (r - g) / delta + 4
            }
            hue *= 60
            if hue < 0 { hue += 360 }
        }
        return (hue, saturation, lightness)
    }

    /// Distancia perceptual ΔE (CIE76) respecto a otro color.
    func deltaE(to other: LinearRGB) -> Double {
        let a = lab, b = other.lab
        let dl = a.l - b.l, da = a.a - b.a, db = a.b - b.b
        return (dl * dl + da * da + db * db).squareRoot()
    }

    /// Distancia perceptual ΔE (CIEDE2000) respecto a otro color: corrige
    /// las distorsiones de CIE76 (sobre todo en azules y en zonas muy
    /// saturadas), así que da vecinos más fieles al elegir el nombre
    /// descriptivo del catálogo. Formulación estándar (Sharma, Wu & Dalal
    /// 2005), kL = kC = kH = 1.
    func deltaE2000(to other: LinearRGB) -> Double {
        func deg2rad(_ d: Double) -> Double { d * .pi / 180 }
        func rad2deg(_ r: Double) -> Double { r * 180 / .pi }

        let l1 = lab, l2 = other.lab

        let c1 = (l1.a * l1.a + l1.b * l1.b).squareRoot()
        let c2 = (l2.a * l2.a + l2.b * l2.b).squareRoot()
        let cBar = (c1 + c2) / 2

        let cBar7 = pow(cBar, 7)
        let g = 0.5 * (1 - (cBar7 / (cBar7 + pow(25, 7))).squareRoot())

        let a1p = l1.a * (1 + g)
        let a2p = l2.a * (1 + g)
        let c1p = (a1p * a1p + l1.b * l1.b).squareRoot()
        let c2p = (a2p * a2p + l2.b * l2.b).squareRoot()

        func hueAngle(_ a: Double, _ b: Double) -> Double {
            guard a != 0 || b != 0 else { return 0 }
            var h = rad2deg(atan2(b, a))
            if h < 0 { h += 360 }
            return h
        }
        let h1p = hueAngle(a1p, l1.b)
        let h2p = hueAngle(a2p, l2.b)

        let dLp = l2.l - l1.l
        let dCp = c2p - c1p

        let dhp: Double
        if c1p * c2p == 0 {
            dhp = 0
        } else if abs(h2p - h1p) <= 180 {
            dhp = h2p - h1p
        } else if h2p - h1p > 180 {
            dhp = h2p - h1p - 360
        } else {
            dhp = h2p - h1p + 360
        }
        let dHp = 2 * (c1p * c2p).squareRoot() * sin(deg2rad(dhp) / 2)

        let lBarP = (l1.l + l2.l) / 2
        let cBarP = (c1p + c2p) / 2

        let hBarP: Double
        if c1p * c2p == 0 {
            hBarP = h1p + h2p
        } else if abs(h1p - h2p) <= 180 {
            hBarP = (h1p + h2p) / 2
        } else if h1p + h2p < 360 {
            hBarP = (h1p + h2p + 360) / 2
        } else {
            hBarP = (h1p + h2p - 360) / 2
        }

        let t = 1
            - 0.17 * cos(deg2rad(hBarP - 30))
            + 0.24 * cos(deg2rad(2 * hBarP))
            + 0.32 * cos(deg2rad(3 * hBarP + 6))
            - 0.20 * cos(deg2rad(4 * hBarP - 63))

        let dTheta = 30 * exp(-pow((hBarP - 275) / 25, 2))
        let cBarP7 = pow(cBarP, 7)
        let rc = 2 * (cBarP7 / (cBarP7 + pow(25, 7))).squareRoot()
        let sl = 1 + (0.015 * pow(lBarP - 50, 2)) / (20 + pow(lBarP - 50, 2)).squareRoot()
        let sc = 1 + 0.045 * cBarP
        let sh = 1 + 0.015 * cBarP * t
        let rt = -sin(deg2rad(2 * dTheta)) * rc

        let termL = dLp / sl
        let termC = dCp / sc
        let termH = dHp / sh
        return (termL * termL + termC * termC + termH * termH + rt * termC * termH).squareRoot()
    }

    /// Construye un color desde coordenadas CIELAB (D65): la inversa de
    /// `lab`. Se usa para reportar la mediana de un cluster calculada en
    /// espacio Lab (perceptual) de vuelta en RGB lineal para guardarla.
    static func fromLab(l: Double, a: Double, b: Double) -> LinearRGB {
        func finv(_ t: Double) -> Double {
            let cubed = t * t * t
            return cubed > 0.008856 ? cubed : (t - 16.0 / 116.0) / 7.787
        }
        let fy = (l + 16) / 116
        let fx = a / 500 + fy
        let fz = fy - b / 200

        // Blanco de referencia D65
        let x = 0.95047 * finv(fx)
        let y = finv(fy)
        let z = 1.08883 * finv(fz)

        // XYZ (D65) -> RGB lineal sRGB, inversa de la matriz usada en `lab`.
        let r = 3.2404542 * x - 1.5371385 * y - 0.4985314 * z
        let g = -0.9692660 * x + 1.8760108 * y + 0.0415560 * z
        let bl = 0.0556434 * x - 0.2040259 * y + 1.0572252 * z
        return LinearRGB(red: max(0, r), green: max(0, g), blue: max(0, bl))
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
