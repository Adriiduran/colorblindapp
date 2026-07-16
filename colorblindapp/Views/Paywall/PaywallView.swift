//
//  PaywallView.swift
//  colorblindapp
//

import Foundation
import StoreKit
import SwiftUI

/// Paywall de la suscripción premium: armario ilimitado, generador de
/// outfits e historial de color sin límite.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PurchaseManager.self) private var purchaseManager
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false

    /// Explica por qué ha aparecido el paywall en este punto concreto.
    var reason: LocalizedStringResource?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    benefits
                    if purchaseManager.products.isEmpty {
                        if purchaseManager.isLoadingProducts {
                            ProgressView()
                                .padding(.top, 8)
                        }
                    } else {
                        productPicker
                    }
                    if let error = purchaseManager.purchaseError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                            .multilineTextAlignment(.center)
                    }
                    actions
                    legalFooter
                }
                .padding(24)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await purchaseManager.loadProducts()
            if selectedProduct == nil {
                selectedProduct = purchaseManager.products.first { $0.id == PurchaseManager.ProductID.annual.rawValue }
                    ?? purchaseManager.products.first
            }
        }
        .onChange(of: purchaseManager.isPremium) {
            if purchaseManager.isPremium {
                dismiss()
            }
        }
    }

    // MARK: - Cabecera

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("Hazte premium")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            if let reason {
                Text(reason)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text("7 días de prueba gratis en cualquier plan")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tint)
        }
    }

    // MARK: - Beneficios

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 14) {
            benefitRow(
                icon: "tshirt.fill",
                title: "Armario ilimitado",
                detail: "Añade toda tu ropa sin límite de prendas."
            )
            benefitRow(
                icon: "sparkles",
                title: "Generador de outfits",
                detail: "Combinaciones puntuadas y explicadas para vestirte con confianza."
            )
            benefitRow(
                icon: "clock.fill",
                title: "Historial ilimitado",
                detail: "Guarda todos los colores que escanees, sin borrar los antiguos."
            )
            benefitRow(
                icon: "bag.badge.questionmark",
                title: "Modo compra",
                detail: "Comprueba en la tienda si una prenda combina con tu armario antes de comprarla."
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func benefitRow(icon: String, title: LocalizedStringKey, detail: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Planes

    /// Ahorro real del plan anual frente a pagar el mensual doce veces,
    /// calculado a partir de los precios que devuelve StoreKit (no
    /// hardcodeado, para que el copy nunca se desincronice del precio real).
    private var annualSavingsText: String? {
        guard
            let monthly = purchaseManager.products.first(where: { $0.id == PurchaseManager.ProductID.monthly.rawValue }),
            let annual = purchaseManager.products.first(where: { $0.id == PurchaseManager.ProductID.annual.rawValue }),
            monthly.price > 0
        else { return nil }

        let monthlyValue = (monthly.price as NSDecimalNumber).doubleValue
        let annualValue = (annual.price as NSDecimalNumber).doubleValue
        let yearlyIfMonthly = monthlyValue * 12
        guard yearlyIfMonthly > annualValue else { return nil }

        let percent = ((yearlyIfMonthly - annualValue) / yearlyIfMonthly * 100).rounded()
        guard percent > 0 else { return nil }
        return String(localized: "Ahorra un \(Int(percent))% frente al plan mensual")
    }

    private var productPicker: some View {
        VStack(spacing: 10) {
            ForEach(purchaseManager.products) { product in
                productCard(product)
            }
        }
    }

    private func productCard(_ product: Product) -> some View {
        let isSelected = selectedProduct?.id == product.id
        return Button {
            selectedProduct = product
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .font(.headline)
                    if product.id == PurchaseManager.ProductID.annual.rawValue, let annualSavingsText {
                        Text(annualSavingsText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.headline.monospacedDigit())
            }
            .padding(14)
            .background(
                isSelected ? AnyShapeStyle(.tint.opacity(0.15)) : AnyShapeStyle(Color(.secondarySystemGroupedBackground)),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.clear), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Acciones

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                purchase()
            } label: {
                if isPurchasing {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Empezar prueba gratis de 7 días")
                        .singleLineFitted()
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(selectedProduct == nil || isPurchasing)

            Button("Restaurar compras") {
                Task { await purchaseManager.restorePurchases() }
            }
            .buttonStyle(.borderless)
        }
    }

    private var legalFooter: some View {
        Text("Incluye 7 días de prueba gratis. Pasado ese periodo, la suscripción se cobra y se renueva automáticamente al precio indicado, salvo que la canceles al menos 24 horas antes de que termine el periodo de prueba o el periodo actual, desde los ajustes de tu cuenta de Apple.")
            .font(.caption)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
    }

    private func purchase() {
        guard let selectedProduct else { return }
        isPurchasing = true
        Task {
            await purchaseManager.purchase(selectedProduct)
            isPurchasing = false
        }
    }
}

#Preview {
    PaywallView(reason: "Tu armario gratis está al completo.")
        .environment(PurchaseManager())
}
