import Foundation
import Observation
import StoreKit

/// ViewModel de la pantalla de pago: envuelve `PurchaseService` y
/// `EntitlementStore` para exponer productos, selección y acciones de compra.
@MainActor
@Observable
final class PaywallViewModel {
    /// Dependencias inyectadas desde el entorno (puede no haberse configurado aún).
    private var deps: AppDependencies?

    /// Producto seleccionado por el usuario en las tarjetas.
    var selectedProduct: Product?

    /// Mensaje de error a mostrar bajo las tarjetas, si lo hay.
    var errorMessage: String?

    /// Productos disponibles (lista vacía si StoreKit no está configurado).
    var products: [Product] {
        deps?.purchases.products ?? []
    }

    /// Pasarela al estado premium actual.
    var isPremium: Bool {
        deps?.entitlements.isPremium ?? false
    }

    /// Indica si hay una compra en curso (para deshabilitar la interfaz).
    var purchaseInProgress: Bool {
        deps?.purchases.purchaseInProgress ?? false
    }

    /// Conecta el ViewModel con las dependencias de la app.
    func configure(deps: AppDependencies?) {
        self.deps = deps
    }

    /// Carga los productos y preselecciona el plan anual si existe.
    func load() async {
        guard let deps else { return }
        await deps.purchases.loadProducts()
        if selectedProduct == nil {
            let loaded = deps.purchases.products
            selectedProduct = loaded.first { $0.id == AppConfig.yearlyProductID } ?? loaded.first
        }
    }

    /// Lanza la compra del producto seleccionado.
    /// - Returns: `true` si la compra se completó y verificó.
    func purchase() async -> Bool {
        guard let deps, let product = selectedProduct else { return false }
        errorMessage = nil
        do {
            return try await deps.purchases.purchase(product)
        } catch {
            errorMessage = String(
                localized: "paywall.error.purchase",
                defaultValue: "No se pudo completar la compra. Inténtalo de nuevo."
            )
            return false
        }
    }

    /// Restaura compras anteriores y refresca los derechos.
    func restore() async {
        await deps?.purchases.restore()
    }
}
