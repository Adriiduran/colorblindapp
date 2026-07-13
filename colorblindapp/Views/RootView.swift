//
//  RootView.swift
//  colorblindapp
//

import SwiftData
import SwiftUI

/// Decide entre el onboarding y la app principal según exista o no
/// un perfil de usuario.
struct RootView: View {
    @Query private var profiles: [UserProfile]

    var body: some View {
        if let profile = profiles.first {
            MainTabView(profile: profile)
        } else {
            OnboardingView()
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [UserProfile.self, SavedColor.self], inMemory: true)
}
