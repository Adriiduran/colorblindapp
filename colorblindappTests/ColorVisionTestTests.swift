//
//  ColorVisionTestTests.swift
//  colorblindappTests
//

import Testing
@testable import colorblindapp

struct ColorVisionTestTests {
    private let plates = ColorVisionTest.plates

    /// Respuestas correctas salvo en las láminas indicadas (id → nil).
    private func answers(missing ids: Set<Int>) -> [Int: Int?] {
        var result: [Int: Int?] = [:]
        for plate in plates {
            result[plate.id] = ids.contains(plate.id) ? .some(nil) : .some(plate.digit)
        }
        return result
    }

    private func ids(_ kind: PlateKind, count: Int) -> Set<Int> {
        Set(plates.filter { $0.kind == kind }.prefix(count).map(\.id))
    }

    @Test func plateStructure() {
        #expect(plates.count == 13)
        #expect(Set(plates.map(\.id)).count == 13)
        #expect(plates.filter { $0.kind == .control }.count == 2)
        #expect(plates.filter { $0.kind == .deutan }.count == 4)
        #expect(plates.filter { $0.kind == .protan }.count == 4)
        #expect(plates.filter { $0.kind == .tritan }.count == 3)
    }

    @Test func allCorrectIsNormal() {
        let outcome = ColorVisionTest.outcome(for: answers(missing: []))
        #expect(outcome.isConclusive && outcome.visionType == .normal)
    }

    @Test func missingAnswersCountAsMisses() {
        let outcome = ColorVisionTest.outcome(for: [:])
        #expect(!outcome.isConclusive)
    }

    @Test func failedControlIsInconclusive() {
        let outcome = ColorVisionTest.outcome(for: answers(missing: ids(.control, count: 1)))
        #expect(!outcome.isConclusive)
        #expect(outcome.visionType == .normal && outcome.severity == .unknown)
    }

    @Test func mildDeutan() {
        let outcome = ColorVisionTest.outcome(for: answers(missing: ids(.deutan, count: 2)))
        #expect(outcome.isConclusive && outcome.visionType == .deutan && outcome.severity == .mild)
    }

    @Test func strongProtan() {
        let outcome = ColorVisionTest.outcome(for: answers(missing: ids(.protan, count: 4)))
        #expect(outcome.visionType == .protan && outcome.severity == .strong)
    }

    @Test func singleMissIsStillNormal() {
        let outcome = ColorVisionTest.outcome(for: answers(missing: ids(.deutan, count: 1).union(ids(.tritan, count: 1))))
        #expect(outcome.isConclusive && outcome.visionType == .normal)
    }

    @Test func tritan() {
        let mild = ColorVisionTest.outcome(for: answers(missing: ids(.tritan, count: 2)))
        #expect(mild.visionType == .tritan && mild.severity == .mild)
        let strong = ColorVisionTest.outcome(for: answers(missing: ids(.tritan, count: 3)))
        #expect(strong.visionType == .tritan && strong.severity == .strong)
    }

    @Test func tritanWinsOnlyWhenRatioIsHigher() {
        // 2/4 rojo-verde (0.5) frente a 3/3 tritán (1.0): gana tritán.
        let tritanWins = ColorVisionTest.outcome(for: answers(missing: ids(.deutan, count: 2).union(ids(.tritan, count: 3))))
        #expect(tritanWins.visionType == .tritan)
        // 4/4 rojo-verde (1.0) frente a 3/3 tritán (1.0): empate, gana rojo-verde.
        let tie = ColorVisionTest.outcome(for: answers(missing: ids(.deutan, count: 4).union(ids(.tritan, count: 3))))
        #expect(tie.visionType == .deutan)
    }

    @Test func shapesVariant() {
        var correct: [Int: TestShape?] = [:]
        for plate in plates { correct[plate.id] = .some(plate.shape) }
        #expect(ColorVisionTest.outcome(forShapes: correct).visionType == .normal)
        for plate in plates where plate.kind == .deutan { correct[plate.id] = .some(nil) }
        let outcome = ColorVisionTest.outcome(forShapes: correct)
        #expect(outcome.visionType == .deutan && outcome.severity == .strong)
    }
}
