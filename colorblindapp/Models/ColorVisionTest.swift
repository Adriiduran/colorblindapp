//
//  ColorVisionTest.swift
//  colorblindapp
//

import Foundation

/// Qué eje de confusión evalúa una lámina. Las de control son visibles
/// para todo el mundo y detectan respuestas poco fiables.
enum PlateKind: String {
    case control
    case protan
    case deutan
    case tritan
}

/// Una lámina pseudo-isocromática. El dígito y el fondo son un par de
/// confusión exacto para el eje `kind`: colores calculados con las matrices
/// de Viénot desplazando el fondo a lo largo de la línea de confusión, de
/// modo que un dicrómata de ese eje los percibe idénticos.
struct TestPlate: Identifiable {
    let id: Int
    let digit: Int
    let kind: PlateKind
    let backgroundHex: String
    let digitHex: String
    let seed: UInt64
}

/// Resultado agregado del test.
struct TestOutcome {
    let isConclusive: Bool
    let visionType: ColorVisionType
    let severity: ColorVisionSeverity
}

enum ColorVisionTest {
    /// Láminas intercaladas para que dos del mismo eje no vayan seguidas.
    static let plates: [TestPlate] = [
        TestPlate(id: 1, digit: 7, kind: .control, backgroundHex: "#E3C99B", digitHex: "#2F6B8F", seed: 11),
        TestPlate(id: 2, digit: 3, kind: .deutan, backgroundHex: "#C8783C", digitHex: "#909835", seed: 22),
        TestPlate(id: 3, digit: 2, kind: .protan, backgroundHex: "#AA6E3C", digitHex: "#D7613B", seed: 33),
        TestPlate(id: 4, digit: 6, kind: .tritan, backgroundHex: "#8CA0AA", digitHex: "#9598CF", seed: 44),
        TestPlate(id: 5, digit: 8, kind: .deutan, backgroundHex: "#8C8246", digitHex: "#C6594B", seed: 55),
        TestPlate(id: 6, digit: 6, kind: .protan, backgroundHex: "#C86E46", digitHex: "#9B7847", seed: 66),
        TestPlate(id: 7, digit: 4, kind: .control, backgroundHex: "#D9B48A", digitHex: "#4A7A52", seed: 77),
        TestPlate(id: 8, digit: 9, kind: .tritan, backgroundHex: "#B9AA8C", digitHex: "#C1A0C6", seed: 88),
        TestPlate(id: 9, digit: 5, kind: .deutan, backgroundHex: "#B98750", digitHex: "#7DA14C", seed: 99),
        TestPlate(id: 10, digit: 9, kind: .protan, backgroundHex: "#967D4B", digitHex: "#CF714A", seed: 110),
        TestPlate(id: 11, digit: 3, kind: .tritan, backgroundHex: "#AFA5AF", digitHex: "#B49FCC", seed: 121),
        TestPlate(id: 12, digit: 2, kind: .deutan, backgroundHex: "#827855", digitHex: "#C4405A", seed: 132),
        TestPlate(id: 13, digit: 5, kind: .protan, backgroundHex: "#B97D5A", digitHex: "#7D875B", seed: 143),
    ]

    /// Calcula el resultado. `answers` mapea id de lámina → dígito respondido
    /// (nil si el usuario no vio ningún número).
    static func outcome(for answers: [Int: Int?]) -> TestOutcome {
        var misses: [PlateKind: Int] = [:]
        for plate in plates {
            let answer = answers[plate.id] ?? nil
            if answer != plate.digit {
                misses[plate.kind, default: 0] += 1
            }
        }

        // Fallar una lámina de control invalida el test (mala luz, respuestas
        // al azar…): mejor no concluir nada que concluir mal.
        if misses[.control, default: 0] > 0 {
            return TestOutcome(isConclusive: false, visionType: .normal, severity: .unknown)
        }

        let protan = misses[.protan, default: 0]
        let deutan = misses[.deutan, default: 0]
        let tritan = misses[.tritan, default: 0]

        let redGreenAxis = max(protan, deutan)
        let hasRedGreen = redGreenAxis >= 2 // de 4 láminas por eje
        let hasTritan = tritan >= 2 // de 3 láminas

        if hasRedGreen && (!hasTritan || Double(redGreenAxis) / 4 >= Double(tritan) / 3) {
            let type: ColorVisionType = protan > deutan ? .protan : .deutan
            let severity: ColorVisionSeverity = redGreenAxis == 4 ? .strong : .mild
            return TestOutcome(isConclusive: true, visionType: type, severity: severity)
        }
        if hasTritan {
            return TestOutcome(isConclusive: true, visionType: .tritan, severity: tritan == 3 ? .strong : .mild)
        }
        return TestOutcome(isConclusive: true, visionType: .normal, severity: .unknown)
    }
}
