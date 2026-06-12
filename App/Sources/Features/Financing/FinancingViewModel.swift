//
//  FinancingViewModel.swift
//  Subscription Guardian
//
//  ViewModel de la lista de financiaciones BNPL: carga, totales agregados
//  y acciones sobre cuotas.
//

import Foundation
import Observation
import SubscriptionGuardianCore

@MainActor
@Observable
final class FinancingViewModel {
    /// Todas las financiaciones (activas y completadas).
    var financings: [Financing] = []
    /// Mensaje de error mostrable en la vista.
    var errorMessage: String?
    /// Indica que se alcanzó el límite del plan gratuito.
    var showPaywall = false

    private var dependencies: AppDependencies?

    /// Capital pendiente total de las financiaciones activas.
    var totalPendingCapital: Decimal {
        financings
            .filter { $0.status == .active }
            .reduce(Decimal(0)) { $0 + $1.pendingCapital }
    }

    /// Compromiso mensual total (suma de cuotas activas con cuotas pendientes).
    var monthlyCommitment: Decimal {
        financings
            .filter { $0.status == .active && $0.pendingInstallments > 0 }
            .reduce(Decimal(0)) { $0 + $1.monthlyAmount }
    }

    /// Número de financiaciones activas.
    var activeCount: Int {
        financings.filter { $0.status == .active }.count
    }

    func configure(deps: AppDependencies?) {
        dependencies = deps
    }

    func load() {
        guard let deps = dependencies else { return }
        do {
            financings = try deps.financings.all()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ financing: Financing) {
        guard let deps = dependencies else { return }
        try? deps.financings.delete(financing)
        load()
    }
}
