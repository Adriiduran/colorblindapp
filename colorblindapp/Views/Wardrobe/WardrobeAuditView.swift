//
//  WardrobeAuditView.swift
//  colorblindapp
//

import SwiftData
import SwiftUI

/// Informe de auditoría del armario: distribución de color (gratis) y,
/// tras el paywall, % de prendas confundibles con el daltonismo del
/// usuario, huecos del armario y una lista de compra priorizada.
struct WardrobeAuditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PurchaseManager.self) private var purchaseManager
    @Query private var garments: [Garment]
    @Query private var profiles: [UserProfile]

    @State private var showPaywall = false

    private static let minimumGarments = 4

    private var visionType: ColorVisionType {
        profiles.first?.visionType ?? .normal
    }

    var body: some View {
        NavigationStack {
            Group {
                if garments.count < Self.minimumGarments {
                    emptyState
                } else {
                    content
                }
            }
            .navigationTitle("Auditoría del armario")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(
                reason: "Desbloquea el informe completo: qué colores se te pueden confundir, los huecos de tu armario y una lista de compra priorizada."
            )
        }
    }

    // MARK: - Estado mínimo

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Añade más prendas", systemImage: "chart.bar.xaxis")
        } description: {
            Text("Necesito al menos \(Self.minimumGarments) prendas en tu armario para darte un informe útil.")
        }
    }

    // MARK: - Contenido

    private var content: some View {
        let auditReport = WardrobeAudit.report(for: garments, visionType: visionType)
        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                distributionSection(auditReport)
                if purchaseManager.isPremium {
                    confusablesSection(auditReport)
                    gapsSection(auditReport)
                    recommendationsSection(auditReport)
                } else {
                    lockedSection
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Distribución (gratis)

    private func distributionSection(_ report: WardrobeAudit.Report) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Distribución de color")
                .font(.headline)
                .padding(.horizontal)
            VStack(spacing: 10) {
                ForEach(report.distribution) { slice in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(slice.color)
                            .strokeBorder(.quaternary, lineWidth: 1)
                            .frame(width: 28, height: 28)
                        Text(slice.name)
                            .font(.subheadline)
                            .singleLineFitted()
                        Spacer()
                        Text("\(slice.count)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                        GeometryReader { geometry in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.accentColor.opacity(0.7))
                                .frame(width: geometry.size.width * slice.share, height: 6)
                        }
                        .frame(width: 80, height: 6)
                    }
                }
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }

    // MARK: - Bloqueo premium

    private var lockedSection: some View {
        ContentUnavailableView {
            Label("Informe completo", systemImage: "lock.fill")
        } description: {
            Text("Descubre qué colores se te pueden confundir, los huecos de tu armario y una lista de compra priorizada.")
        } actions: {
            Button {
                showPaywall = true
            } label: {
                Text("Ver planes premium")
                    .singleLineFitted()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal)
    }

    // MARK: - Confundibles (premium)

    private func confusablesSection(_ report: WardrobeAudit.Report) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Colores que se te pueden confundir")
                .font(.headline)
                .padding(.horizontal)
            if visionType == .normal {
                Text("No detectamos daltonismo en tu perfil: no hace falta este análisis.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else if report.confusableClusters.isEmpty {
                Text("No hemos encontrado prendas que se te puedan confundir entre sí. Buen trabajo.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                Text(
                    "El \(Int((report.confusablePercentage * 100).rounded()))% de tus prendas se puede confundir con alguna otra con tu \(visionType.displayName.lowercased())."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                ForEach(report.confusableClusters) { cluster in
                    clusterCard(cluster)
                }
            }
        }
    }

    private func clusterCard(_ cluster: WardrobeAudit.ConfusableCluster) -> some View {
        HStack(spacing: 10) {
            ForEach(cluster.garments) { garment in
                VStack(spacing: 4) {
                    GarmentThumbnail(garment: garment, side: 60)
                    Text(garment.descriptiveName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .frame(width: 60)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Huecos (premium)

    private func gapsSection(_ report: WardrobeAudit.Report) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Huecos en tu armario")
                .font(.headline)
                .padding(.horizontal)
            if report.gaps.isEmpty {
                Text("No hemos encontrado huecos importantes: tu armario está bien equilibrado.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 8) {
                    ForEach(report.gaps) { gap in
                        Label {
                            Text(gap.message)
                                .font(.subheadline)
                        } icon: {
                            Image(systemName: gapIcon(gap.kind))
                                .foregroundStyle(.orange)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func gapIcon(_ kind: WardrobeAudit.GapKind) -> String {
        switch kind {
        case .noNeutrals: "circle.lefthalf.filled"
        case .missingSlot: "square.dashed"
        case .overConcentration: "chart.pie"
        }
    }

    // MARK: - Lista de compra (premium)

    private func recommendationsSection(_ report: WardrobeAudit.Report) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Lista de compra recomendada")
                .font(.headline)
                .padding(.horizontal)
            if report.recommendations.isEmpty {
                Text("No tenemos ninguna recomendación clara: tu armario ya cubre bien los básicos.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 10) {
                    ForEach(report.recommendations) { recommendation in
                        HStack(alignment: .top, spacing: 12) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(recommendation.color)
                                .strokeBorder(.quaternary, lineWidth: 1)
                                .frame(width: 36, height: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(recommendation.name)
                                    .font(.subheadline.weight(.semibold))
                                Text(recommendation.reason)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal)

                Text("Lleva esta lista contigo la próxima vez que vayas de compras.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
        }
    }
}

#Preview {
    WardrobeAuditView()
        .environment(PurchaseManager())
        .modelContainer(for: [UserProfile.self, SavedColor.self, Garment.self, Outfit.self], inMemory: true)
}
