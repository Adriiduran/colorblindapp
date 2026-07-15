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
    static let freeOutfitTrialLimit = 3
    static let freeOutfitTrialInterval: TimeInterval = 7 * 24 * 60 * 60

    private static let freeOutfitTrialUsesKey = "freeOutfitTrialUses"

    private(set) var products: [Product] = []
    private(set) var isLoadingProducts = false
    var purchaseError: String?

    #if DEBUG
    /// Override manual de depuración: fuerza `isPremium` a `true` sin pasar
    /// por StoreKit. Solo para probar features premium sin comprar ni gastar
    /// la cata semanal.
    var debugForcePremium = false
    #endif

    private(set) var hasActiveEntitlement = false

    /// Fechas (dentro de los últimos 7 días) en las que un usuario no
    /// premium ha generado outfits con la cata gratuita semanal.
    private(set) var freeOutfitTrialUses: [Date] = []

    private var transactionListener: Task<Void, Never>?

    init() {
        freeOutfitTrialUses = (UserDefaults.standard.array(forKey: Self.freeOutfitTrialUsesKey) as? [Date]) ?? []
    }

    var isPremium: Bool {
        #if DEBUG
        if debugForcePremium { return true }
        #endif
        return hasActiveEntitlement
    }

    /// Usos de la cata gratuita todavía dentro de la ventana de 7 días.
    private var activeFreeOutfitTrialUses: [Date] {
        let cutoff = Date().addingTimeInterval(-Self.freeOutfitTrialInterval)
        return freeOutfitTrialUses.filter { $0 >= cutoff }
    }

    /// Si el usuario no premium puede generar outfits ahora mismo: le queda
    /// alguna de sus `freeOutfitTrialLimit` generaciones de los últimos 7 días.
    var canUseFreeOutfitTrial: Bool {
        activeFreeOutfitTrialUses.count < Self.freeOutfitTrialLimit
    }

    /// Generaciones gratuitas que le quedan al usuario esta semana.
    var remainingFreeOutfitTrials: Int {
        max(0, Self.freeOutfitTrialLimit - activeFreeOutfitTrialUses.count)
    }

    /// Fecha en la que volverá a estar disponible una generación gratuita,
    /// si ya se ha consumido el cupo.
    var nextFreeOutfitTrialDate: Date? {
        activeFreeOutfitTrialUses.sorted().first?.addingTimeInterval(Self.freeOutfitTrialInterval)
    }

    /// Registra un uso de la cata semanal. Llamar solo cuando un usuario no
    /// premium genera outfits.
    func consumeFreeOutfitTrial() {
        var uses = activeFreeOutfitTrialUses
        uses.append(Date())
        freeOutfitTrialUses = uses
        UserDefaults.standard.set(uses, forKey: Self.freeOutfitTrialUsesKey)
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
        hasActiveEntitlement = active
    }
}
