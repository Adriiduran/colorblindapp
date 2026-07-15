//
//  PurchaseManager.swift
//  colorblindapp
//

import Foundation
import Observation
import StoreKit

/// Suscripción premium vía StoreKit 2: carga los productos, escucha las
/// transacciones y expone si el usuario tiene acceso premium.
///
/// Premium desbloquea: armario ilimitado (gratis se queda en
/// `freeWardrobeLimit`), el generador de outfits ilimitado (gratis tiene una
/// cata semanal, ver `canUseFreeOutfitTrial`) y el historial de color
/// ilimitado (gratis se queda en `freeHistoryLimit`).
@Observable
@MainActor
final class PurchaseManager {
    enum ProductID: String, CaseIterable {
        case monthly = "com.admist.colorblindapp.premium.monthly"
        case annual = "com.admist.colorblindapp.premium.annual"
    }

    static let freeWardrobeLimit = 5
    static let freeHistoryLimit = 10
    static let freeOutfitTrialInterval: TimeInterval = 7 * 24 * 60 * 60

    private static let lastFreeOutfitDateKey = "lastFreeOutfitDate"

    private(set) var products: [Product] = []
    private(set) var isPremium = false
    private(set) var isLoadingProducts = false
    var purchaseError: String?

    /// Última vez que un usuario no premium generó outfits con la cata
    /// gratuita semanal. `nil` si nunca la ha usado.
    private(set) var lastFreeOutfitDate: Date?

    private var transactionListener: Task<Void, Never>?

    init() {
        lastFreeOutfitDate = UserDefaults.standard.object(forKey: Self.lastFreeOutfitDateKey) as? Date
    }

    /// Si el usuario no premium puede generar outfits ahora mismo: nunca lo
    /// ha hecho, o han pasado 7 días desde la última vez.
    var canUseFreeOutfitTrial: Bool {
        guard let lastFreeOutfitDate else { return true }
        return Date().timeIntervalSince(lastFreeOutfitDate) >= Self.freeOutfitTrialInterval
    }

    /// Fecha en la que volverá a estar disponible la cata gratuita, si ya se
    /// ha consumido.
    var nextFreeOutfitTrialDate: Date? {
        lastFreeOutfitDate?.addingTimeInterval(Self.freeOutfitTrialInterval)
    }

    /// Marca la cata semanal como usada hoy. Llamar solo cuando un usuario
    /// no premium genera outfits.
    func consumeFreeOutfitTrial() {
        let now = Date()
        lastFreeOutfitDate = now
        UserDefaults.standard.set(now, forKey: Self.lastFreeOutfitDateKey)
    }

    /// Arranca el listener de transacciones y hace la carga inicial.
    /// Se llama una sola vez al lanzar la app.
    func start() async {
        transactionListener = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
        await loadProducts()
        await refreshEntitlement()
    }

    func loadProducts() async {
        guard products.isEmpty else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            products = try await Product.products(for: ProductID.allCases.map(\.rawValue))
                .sorted { $0.price < $1.price }
        } catch {
            purchaseError = String(localized: "No se pudieron cargar los planes. Comprueba tu conexión.")
        }
    }

    func purchase(_ product: Product) async {
        purchaseError = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await handle(verification)
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = String(localized: "No se pudo completar la compra.")
        }
    }

    func restorePurchases() async {
        purchaseError = nil
        do {
            try await AppStore.sync()
            await refreshEntitlement()
        } catch {
            purchaseError = String(localized: "No se pudieron restaurar las compras.")
        }
    }

    private func handle(_ update: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = update else { return }
        await transaction.finish()
        await refreshEntitlement()
    }

    /// Recorre las suscripciones activas del usuario y actualiza `isPremium`.
    private func refreshEntitlement() async {
        var active = false
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else { continue }
            if ProductID(rawValue: transaction.productID) != nil, transaction.revocationDate == nil {
                active = true
                break
            }
        }
        isPremium = active
    }
}
