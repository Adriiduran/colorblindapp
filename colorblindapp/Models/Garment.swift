//
//  Garment.swift
//  colorblindapp
//

import Foundation
import SwiftData
import SwiftUI

/// Categoría de una prenda del armario.
enum GarmentCategory: String, Codable, CaseIterable, Identifiable {
    case camiseta
    case camisa
    case jersey
    case chaqueta
    case pantalon
    case falda
    case vestido
    case zapatos
    case accesorio
    case otro

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .camiseta: String(localized: "Camiseta")
        case .camisa: String(localized: "Camisa")
        case .jersey: String(localized: "Jersey")
        case .chaqueta: String(localized: "Chaqueta")
        case .pantalon: String(localized: "Pantalón")
        case .falda: String(localized: "Falda")
        case .vestido: String(localized: "Vestido")
        case .zapatos: String(localized: "Zapatos")
        case .accesorio: String(localized: "Accesorio")
        case .otro: String(localized: "Otro")
        }
    }

    var systemImage: String {
        switch self {
        case .camiseta, .camisa, .jersey: "tshirt"
        case .chaqueta: "jacket"
        case .pantalon, .falda, .vestido: "figure.dress.line.vertical.figure"
        case .zapatos: "shoe"
        case .accesorio: "handbag"
        case .otro: "tag"
        }
    }
}

/// Una prenda del armario virtual: la foto recortada y su color dominante,
/// ya analizados al darla de alta.
@Model
final class Garment {
    /// Imagen de la prenda con el fondo eliminado (PNG con transparencia).
    @Attribute(.externalStorage) var imageData: Data

    /// Color dominante en RGB lineal.
    var red: Double
    var green: Double
    var blue: Double

    /// Color secundario (prendas estampadas o de dos tonos), si lo hay.
    var secondaryRed: Double?
    var secondaryGreen: Double?
    var secondaryBlue: Double?

    var basicName: String
    var descriptiveName: String
    private var categoryRaw: String
    var createdAt: Date

    init(
        imageData: Data,
        dominant: LinearRGB,
        secondary: LinearRGB?,
        category: GarmentCategory
    ) {
        self.imageData = imageData
        self.red = dominant.red
        self.green = dominant.green
        self.blue = dominant.blue
        self.secondaryRed = secondary?.red
        self.secondaryGreen = secondary?.green
        self.secondaryBlue = secondary?.blue
        self.basicName = ColorNamer.basicName(for: dominant)
        self.descriptiveName = ColorNamer.descriptiveName(for: dominant)
        self.categoryRaw = category.rawValue
        self.createdAt = .now
    }

    var category: GarmentCategory {
        get { GarmentCategory(rawValue: categoryRaw) ?? .otro }
        set { categoryRaw = newValue.rawValue }
    }

    var dominantColor: LinearRGB {
        LinearRGB(red: red, green: green, blue: blue)
    }

    var secondaryColor: LinearRGB? {
        guard let secondaryRed, let secondaryGreen, let secondaryBlue else { return nil }
        return LinearRGB(red: secondaryRed, green: secondaryGreen, blue: secondaryBlue)
    }

    /// Actualiza el color dominante (corrección manual del usuario).
    func setDominant(_ color: LinearRGB) {
        red = color.red
        green = color.green
        blue = color.blue
        basicName = ColorNamer.basicName(for: color)
        descriptiveName = ColorNamer.descriptiveName(for: color)
    }
}
