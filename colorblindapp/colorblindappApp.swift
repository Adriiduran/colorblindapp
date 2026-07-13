//
//  colorblindappApp.swift
//  colorblindapp
//
//  Created by admist on 12/07/2026.
//

import SwiftData
import SwiftUI

@main
struct colorblindappApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [UserProfile.self, SavedColor.self])
    }
}
