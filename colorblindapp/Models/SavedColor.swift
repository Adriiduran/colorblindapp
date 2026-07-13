//
//  SavedColor.swift
//  colorblindapp
//

import Foundation
import SwiftData
import SwiftUI

/// Un color escaneado con la cámara, guardado en el historial.
@Model
final class SavedColor {
    /// Componentes RGB **lineales** en rango 0...1, fuente de verdad del color.
    var red: Double
    var green: Double
    var blue: Double

    /// Nombre básico ("Verde") y descriptivo ("Verde oliva"), calculados al guardar.
    var basicName: String
    var descriptiveName: String

    var isFavorite: Bool
    var scannedAt: Date

    init(
        red: Double,
        green: Double,
        blue: Double,
        basicName: String,
        descriptiveName: String,
        isFavorite: Bool = false
    ) {
        self.red = red
        self.green = green
        self.blue = blue
        self.basicName = basicName
        self.descriptiveName = descriptiveName
        self.isFavorite = isFavorite
        self.scannedAt = .now
    }

    var linearRGB: LinearRGB {
        LinearRGB(red: red, green: green, blue: blue)
    }

    /// Representación hexadecimal, p. ej. "#6B8E23".
    var hexString: String {
        linearRGB.hexString
    }

    var color: Color {
        linearRGB.color
    }
}
