//
//  MainTabView.swift
//  colorblindapp
//

import SwiftData
import SwiftUI

struct MainTabView: View {
    let profile: UserProfile

    var body: some View {
        TabView {
            Tab("Escáner", systemImage: "camera.viewfinder") {
                ScannerView()
            }
            Tab("Armario", systemImage: "tshirt") {
                WardrobeView()
            }
            Tab("Ajustes", systemImage: "gearshape") {
                SettingsView(profile: profile)
            }
        }
    }
}

#Preview {
    MainTabView(profile: UserProfile(visionType: .deutan))
        .modelContainer(for: [UserProfile.self, SavedColor.self], inMemory: true)
}
