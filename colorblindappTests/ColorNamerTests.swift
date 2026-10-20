//
//  ColorNamerTests.swift
//  colorblindappTests
//

import Foundation
import Testing
@testable import colorblindapp

struct ColorNamerTests {
    private func basic(_ hex: String) -> String {
        ColorNamer.basicName(for: LinearRGB(hex: hex))
    }

    @Test func achromaticNames() {
        #expect(basic("#000000") == String(localized: "Negro"))
        #expect(basic("#FFFFFF") == String(localized: "Blanco"))
        #expect(basic("#808080") == String(localized: "Gris"))
    }

    @Test func hueNames() {
        #expect(basic("#FF0000") == String(localized: "Rojo"))
        #expect(basic("#00A000") == String(localized: "Verde"))
        #expect(basic("#0000FF") == String(localized: "Azul"))
    }

    @Test func descriptiveNameIsNeverEmpty() {
        for hex in ["#C8783C", "#2F6B8F", "#000000", "#FFFFFF", "#7DA14C"] {
            #expect(!ColorNamer.descriptiveName(for: LinearRGB(hex: hex)).isEmpty)
        }
    }

    @Test func perceivedNameNilForNormalVision() {
        #expect(ColorNamer.perceivedName(for: LinearRGB(hex: "#C4405A"), visionType: .normal) == nil)
    }
}
