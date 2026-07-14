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
    @State private var purchaseManager = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(purchaseManager)
                .task {
                    await purchaseManager.start()
                }
        }
        .modelContainer(for: [UserProfile.self, SavedColor.self, Garment.self, Outfit.self])
    }
}
