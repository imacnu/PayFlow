//
//  SubscriptionsViewModel.swift
//  Subscription Guardian
//
//  Lógica de la lista de suscripciones: carga, búsqueda, totales y mutaciones.
//

import Foundation
import Observation
import SubscriptionGuardianCore

/// ViewModel de la lista de suscripciones.
@MainActor
@Observable
final class SubscriptionsViewModel {
    /// Dependencias inyectadas desde la vista vía `configure(deps:)`.
    private var deps: AppDependencies?

    /// Todas las suscripciones del usuario.
    var subscriptions: [Subscription] = []

    /// Texto de búsqueda introducido por el usuario.
    var searchText = ""

    /// Suscripciones filtradas por el texto de búsqueda.
    var filteredSubscriptions: [Subscription] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return subscriptions }
        return subscriptions.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || $0.provider.localizedCaseInsensitiveContains(query)
        }
    }

    /// Número de suscripciones activas.
    var activeCount: Int {
        subscriptions.filter { $0.status == .active }.count
    }

    /// Gasto mensual total de las suscripciones activas.
    var monthlyTotal: Decimal {
        SpendingCalculator.monthlyTotal(subscriptions: subscriptions.map { $0.summary })
    }

    /// Divisa predominante para mostrar el total (la de la primera suscripción).
    var displayCurrencyCode: String {
        subscriptions.first?.currencyCode ?? "EUR"
    }

    /// Inyecta las dependencias de la app. Debe llamarse desde `.task`/onAppear.
    func configure(deps: AppDependencies?) {
        self.deps = deps
    }

    /// Recarga la lista desde el repositorio.
    func load() {
        guard let deps else { return }
        subscriptions = (try? deps.subscriptions.all()) ?? []
    }

    /// Elimina una suscripción y refresca la lista.
    func delete(_ subscription: Subscription) {
        guard let deps else { return }
        try? deps.subscriptions.delete(subscription)
        load()
    }

    /// Cambia el estado de una suscripción y refresca la lista.
    func setStatus(_ subscription: Subscription, status: SubscriptionStatus) {
        guard let deps else { return }
        try? deps.subscriptions.setStatus(subscription, status: status)
        load()
    }

    /// Marca una suscripción como usada recientemente y refresca la lista.
    func markUsed(_ subscription: Subscription) {
        guard let deps else { return }
        try? deps.subscriptions.markUsed(subscription)
        load()
    }
}
