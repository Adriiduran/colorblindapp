//
//  LinearRGBTests.swift
//  colorblindappTests
//

import Testing
@testable import colorblindapp

struct LinearRGBTests {
    @Test func hexRoundTrip() {
        for hex in ["#C8783C", "#000000", "#FFFFFF", "#6B8E23"] {
            #expect(LinearRGB(hex: hex).hexString == hex)
        }
    }

    @Test func blackAndWhiteLab() {
        let black = LinearRGB(hex: "#000000").lab
        let white = LinearRGB(hex: "#FFFFFF").lab
        #expect(abs(black.l) < 0.5)
        #expect(abs(white.l - 100) < 0.5)
        #expect(abs(white.a) < 0.5 && abs(white.b) < 0.5)
    }

    @Test func labRoundTrip() {
        let original = LinearRGB(hex: "#4A7A52")
        let lab = original.lab
        let back = LinearRGB.fromLab(l: lab.l, a: lab.a, b: lab.b)
        #expect(original.deltaE(to: back) < 0.01)
    }

    @Test func hslOfPrimaries() {
        let red = LinearRGB(hex: "#FF0000").hsl
        #expect(abs(red.hue) < 0.5 && abs(red.saturation - 1) < 0.01 && abs(red.lightness - 0.5) < 0.01)
        #expect(abs(LinearRGB(hex: "#00FF00").hsl.hue - 120) < 0.5)
        #expect(abs(LinearRGB(hex: "#0000FF").hsl.hue - 240) < 0.5)
        #expect(LinearRGB(hex: "#808080").hsl.saturation == 0)
    }

    @Test func deltaEIsZeroForSameColorAndSymmetric() {
        let a = LinearRGB(hex: "#C8783C"), b = LinearRGB(hex: "#2F6B8F")
        #expect(a.deltaE(to: a) == 0)
        #expect(a.deltaE2000(to: a) < 1e-9)
        #expect(abs(a.deltaE(to: b) - b.deltaE(to: a)) < 1e-9)
        #expect(abs(a.deltaE2000(to: b) - b.deltaE2000(to: a)) < 1e-6)
        #expect(a.deltaE2000(to: b) > 10)
    }

    /// Pares de referencia de Sharma, Wu & Dalal (2005) sobre CIEDE2000 no se
    /// pueden pasar directamente (el método parte de RGB), así que se
    /// comprueba el orden: un tono cercano está más cerca que uno lejano.
    @Test func deltaE2000OrdersNearAndFar() {
        let base = LinearRGB(hex: "#C8783C")
        let near = LinearRGB(hex: "#C97A3E")
        let far = LinearRGB(hex: "#3C78C8")
        #expect(base.deltaE2000(to: near) < base.deltaE2000(to: far))
    }

    @Test func mixedInterpolates() {
        let a = LinearRGB(red: 0, green: 0, blue: 0)
        let b = LinearRGB(red: 1, green: 0.5, blue: 0.25)
        let mid = a.mixed(with: b, amount: 0.5)
        #expect(mid.red == 0.5 && mid.green == 0.25 && mid.blue == 0.125)
        #expect(a.mixed(with: b, amount: 0).red == 0)
        #expect(a.mixed(with: b, amount: 1).red == 1)
    }

    @Test func seededGeneratorIsDeterministic() {
        var g1 = SeededGenerator(seed: 42), g2 = SeededGenerator(seed: 42)
        #expect((0..<10).map { _ in g1.next() } == (0..<10).map { _ in g2.next() })
        var g3 = SeededGenerator(seed: 43)
        var g4 = SeededGenerator(seed: 42)
        #expect(g3.next() != g4.next())
    }
}
