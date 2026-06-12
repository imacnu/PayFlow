//
//  InsightsViewModel.swift
//  Subscription Guardian
//
//  ViewModel de la analítica mensual y el motor de ahorro.
//

import Foundation
import Observation
import SubscriptionGuardianCore

@MainActor
@Observable
final class InsightsViewModel {
    /// Gasto mensual total actual.
    private(set) var monthlyTotal: Decimal = 0
    /// Proyección de gasto anual.
    private(set) var projectedAnnual: Decimal = 0
    /// Variación porcentual respecto al mes anterior (nil si no hay histórico).
    private(set) var monthlyVariation: Decimal?
    /// Desglose por categoría ordenado de mayor a menor gasto.
    private(set) var categorySlices: [SpendingCalculator.CategorySlice] = []
    /// Recomendaciones generadas por el motor de insights.
    private(set) var insights: [Insight] = []
    /// Ahorro anual potencial total.
    private(set) var totalPotentialSaving: Decimal = 0
    /// Divisa para formatear los importes agregados.
    private(set) var currencyCode: String = "EUR"

    private var dependencies: AppDependencies?

    func configure(deps: AppDependencies?) {
        dependencies = deps
    }

    func load() {
        guard let deps = dependencies else { return }

        let now = Date()
        let calendar = Calendar.current
        let subscriptions = (try? deps.subscriptions.summaries()) ?? []
        let financings = (try? deps.financings.summaries()) ?? []

        currencyCode = subscriptions.first { $0.status == .active }?.currencyCode ?? "EUR"

        monthlyTotal = SpendingCalculator.monthlyTotal(
            subscriptions: subscriptions,
            financings: financings
        )
        projectedAnnual = SpendingCalculator.projectedAnnual(
            subscriptions: subscriptions,
            financings: financings
        )

        let evolution = SpendingCalculator.monthlyEvolution(
            subscriptions: subscriptions,
            financings: financings,
            months: 6,
            now: now,
            calendar: calendar
        )
        monthlyVariation = SpendingCalculator.monthOverMonthVariation(evolution: evolution)

        categorySlices = SpendingCalculator.categoryBreakdown(subscriptions: subscriptions)

        insights = InsightsEngine.generate(
            subscriptions: subscriptions,
            financings: financings,
            now: now,
            calendar: calendar
        )
        totalPotentialSaving = InsightsEngine.totalPotentialAnnualSaving(insights)
    }
}
