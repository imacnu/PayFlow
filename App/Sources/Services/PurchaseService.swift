import Foundation
import Observation
import StoreKit

/// Servicio de compras dentro de la app (suscripción premium).
@MainActor
@Observable
final class PurchaseService {
    /// Productos disponibles, ordenados por precio ascendente.
    var products: [Product] = []
    /// Indica si hay una compra en curso (para deshabilitar la interfaz).
    var purchaseInProgress = false

    private let entitlements: EntitlementStore

    init(entitlements: EntitlementStore) {
        self.entitlements = entitlements
    }

    /// Carga los productos configurados en `AppConfig.productIDs`.
    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: AppConfig.productIDs)
            products = loaded.sorted { $0.price < $1.price }
        } catch {
            // Sin conexión o sin configuración de StoreKit: dejamos la lista vacía.
            products = []
        }
    }

    /// Lanza la compra del producto indicado.
    /// - Returns: `true` si la compra se completó y verificó; `false` si el
    ///   usuario canceló, quedó pendiente o no se pudo verificar.
    func purchase(_ product: Product) async throws -> Bool {
        purchaseInProgress = true
        defer { purchaseInProgress = false }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                await entitlements.refresh()
                return true
            case .unverified:
                // Transacción no verificable: no concedemos el derecho.
                return false
            }
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    /// Restaura compras sincronizando con la App Store y refresca los derechos.
    func restore() async {
        try? await AppStore.sync()
        await entitlements.refresh()
    }
}
