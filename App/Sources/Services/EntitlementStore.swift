import Foundation
import Observation
import StoreKit

/// Estado de derechos del usuario (premium o plan gratuito) y límites asociados.
@MainActor
@Observable
final class EntitlementStore {
    /// Indica si el usuario tiene la suscripción premium activa.
    var isPremium = false

    /// Tarea que escucha actualizaciones de transacciones de StoreKit.
    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    /// Indica si se puede añadir otra suscripción con el plan actual.
    func canAddSubscription(currentCount: Int) -> Bool {
        isPremium || currentCount < AppConfig.freeSubscriptionLimit
    }

    /// Indica si se puede añadir otra financiación con el plan actual.
    func canAddFinancing(currentCount: Int) -> Bool {
        isPremium || currentCount < AppConfig.freeFinancingLimit
    }

    /// Recalcula `isPremium` a partir de los derechos vigentes en StoreKit.
    func refresh() async {
        var premium = false
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               AppConfig.productIDs.contains(transaction.productID),
               transaction.revocationDate == nil {
                premium = true
            }
        }
        isPremium = premium
    }

    /// Arranca (una sola vez) la escucha de actualizaciones de transacciones,
    /// refrescando los derechos con cada cambio.
    func listenForUpdates() {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await _ in StoreKit.Transaction.updates {
                await self?.refresh()
            }
        }
    }

    deinit {
        updatesTask?.cancel()
    }
}
