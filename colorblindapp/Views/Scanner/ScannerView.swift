//
//  ScannerView.swift
//  colorblindapp
//

import SwiftUI

/// Escáner de color con cámara. Placeholder hasta el hito 3.
struct ScannerView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Escáner de color",
                systemImage: "camera.viewfinder",
                description: Text("Apunta la cámara a cualquier objeto para identificar su color. Disponible próximamente.")
            )
            .navigationTitle("Escáner")
        }
    }
}

#Preview {
    ScannerView()
}
