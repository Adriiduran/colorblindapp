//
//  UserProfile.swift
//  colorblindapp
//

import Foundation
import SwiftData

/// Perfil del usuario. Solo debe existir una instancia; su presencia indica
/// que el onboarding está completado.
@Model
final class UserProfile {
    // SwiftData almacena los enums como su raw value; se exponen tipados abajo.
    private var visionTypeRaw: String
    private var severityRaw: String

    /// Fecha del último test realizado; nil si el tipo se eligió manualmente.
    var testDate: Date?
    var wasSetManually: Bool
    var createdAt: Date

    init(
        visionType: ColorVisionType,
        severity: ColorVisionSeverity = .unknown,
        testDate: Date? = nil,
        wasSetManually: Bool = false
    ) {
        self.visionTypeRaw = visionType.rawValue
        self.severityRaw = severity.rawValue
        self.testDate = testDate
        self.wasSetManually = wasSetManually
        self.createdAt = .now
    }

    var visionType: ColorVisionType {
        get { ColorVisionType(rawValue: visionTypeRaw) ?? .normal }
        set { visionTypeRaw = newValue.rawValue }
    }

    var severity: ColorVisionSeverity {
        get { ColorVisionSeverity(rawValue: severityRaw) ?? .unknown }
        set { severityRaw = newValue.rawValue }
    }
}
