//
//  WardrobeHomeView.swift
//  colorblindapp
//

import SwiftData
import SwiftUI

/// Sección del control segmentado que unifica Armario y Outfits: son la
/// misma tarea (vestirse) y no merecen pestañas separadas en el tab bar.
enum WardrobeSection: String, CaseIterable, Identifiable {
    case garments
    case outfits

    var id: Self { self }

    var title: String {
        switch self {
        case .garments: String(localized: "Prendas")
        case .outfits: String(localized: "Outfits")
        }
    }
}

/// Pestaña "Armario": hospeda `WardrobeView` y `OutfitsView` bajo un único
/// `NavigationStack`, alternando con un control segmentado.
struct WardrobeHomeView: View {
    @Query(sort: \Garment.createdAt, order: .reverse) private var garments: [Garment]
    @State private var section: WardrobeSection = .garments

    var body: some View {
        NavigationStack {
            Group {
                switch section {
                case .garments:
                    WardrobeView()
                case .outfits:
                    OutfitsView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Sección", selection: $section) {
                        ForEach(WardrobeSection.allCases) { section in
                            Text(section.title).tag(section)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 240)
                }
            }
        }
    }
}

#Preview {
    WardrobeHomeView()
        .environment(PurchaseManager())
        .modelContainer(for: [UserProfile.self, SavedColor.self, Garment.self, Outfit.self], inMemory: true)
}
