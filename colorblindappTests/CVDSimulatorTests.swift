//
//  CVDSimulatorTests.swift
//  colorblindappTests
//

import Testing
@testable import colorblindapp

struct CVDSimulatorTests {
    @Test func normalReturnsInput() {
        let c = LinearRGB(hex: "#C8783C")
        #expect(CVDSimulator.simulate(c, type: .normal).hexString == c.hexString)
    }

    @Test func outputStaysInRange() {
        for hex in ["#FF0000", "#00FF00", "#0000FF", "#FFFFFF", "#000000", "#C4405A"] {
            for type in [ColorVisionType.protan, .deutan, .tritan] {
                let out = CVDSimulator.simulate(LinearRGB(hex: hex), type: type)
                for v in [out.red, out.green, out.blue] {
                    #expect(v >= 0 && v <= 1)
                }
            }
        }
    }

    @Test func grayIsPreserved() {
        let gray = LinearRGB(hex: "#808080")
        for type in [ColorVisionType.protan, .deutan, .tritan] {
            #expect(gray.deltaE(to: CVDSimulator.simulate(gray, type: type)) < 3)
        }
    }

    @Test func redAndGreenCollapseForDeutan() {
        let red = LinearRGB(hex: "#C4405A"), green = LinearRGB(hex: "#7DA14C")
        let original = red.deltaE(to: green)
        let simulated = CVDSimulator.simulate(red, type: .deutan)
            .deltaE(to: CVDSimulator.simulate(green, type: .deutan))
        #expect(simulated < original)
    }
}
