//
//  GuestTestView.swift
//  colorblindapp
//

import SwiftUI

/// Test de daltonismo a otra persona: nunca lee ni escribe el `UserProfile`
/// del usuario, es puramente transitorio. Antes de empezar pregunta si la
/// persona es un niño pequeño o un adulto, para elegir la variante del test.
struct GuestTestView: View {
    private enum GuestAge {
        case adult
        case child
    }

    @State private var mode: GuestAge?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch mode {
            case nil:
                ageSelector
            case .adult:
                ColorVisionTestView(showsSaveButton: false) { _ in }
            case .child:
                ChildColorVisionTestView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cerrar") {
                    dismiss()
                }
            }
        }
    }

    private var ageSelector: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "person.2")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("Test a otra persona")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("El resultado solo se muestra en pantalla: no se guarda ni cambia tu perfil.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Text("¿A quién le vas a hacer el test?")
                .font(.headline)

            Button {
                mode = .adult
            } label: {
                Text("Un adulto")
                    .singleLineFitted()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button {
                mode = .child
            } label: {
                Text("Un niño pequeño")
                    .singleLineFitted()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(24)
        .navigationTitle("Test a otra persona")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        GuestTestView()
    }
}
