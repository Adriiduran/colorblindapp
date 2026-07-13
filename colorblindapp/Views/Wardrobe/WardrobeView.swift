//
//  WardrobeView.swift
//  colorblindapp
//

import SwiftUI

/// Armario virtual y generador de outfits. Placeholder hasta la Fase 2.
struct WardrobeView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Armario virtual",
                systemImage: "tshirt",
                description: Text("Sube fotos de tu ropa y te ayudaremos a combinarla. Disponible próximamente.")
            )
            .navigationTitle("Armario")
        }
    }
}

#Preview {
    WardrobeView()
}
