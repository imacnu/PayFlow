//
//  DashboardViewModel.swift
//  Subscription Guardian
//
//  ViewModel del panel principal: agrega los datos de suscripciones,
//  financiaciones y notificaciones en los indicadores del dashboard.
//

import Foundation
import Observation
import SubscriptionGuardianCore

@MainActor
@Observable
final class DashboardViewModel {
    /// Próximo pago unificado: renovación de suscripción o cuota de financiación.
    struct UpcomingItem: Identifiable, Hashable {
        let id: String
        let name: String
        let amount: Decimal
        let currencyCode: String
        let date: Date
        let isFinancing: Bool
    }

    // MARK: - Estado expuesto a la vista

    /// Gasto mensual total (suscripciones activas + cuotas activas).
    private(set) var monthlyTotal: Decimal = 0
    /// Número de suscripciones activas.
    private(set) var activeSubscriptionsCount: Int = 0
    /// Número de financiaciones activas.
    private(set) var activeFinancingsCount: Int = 0
    /// Próximos pagos combinados, ordenados por fecha (máximo 5).
    private(set) var upcomingPayments: [UpcomingItem] = []
    /// Ahorro anual potencial estimado por el motor de insights.
    private(set) var potentialSaving: Decimal = 0
    /// Desglose del gasto mensual por categoría.
    private(set) var categorySlices: [SpendingCalculator.CategorySlice] = []
    /// Evolución del gasto en los últimos 6 meses.
    private(set) var evolution: [SpendingCalculator.MonthPoint] = []
    /// Número de notificaciones sin leer.
    private(set) var unreadNotifications: Int = 0
    /// Divisa predominante para formatear los totales agregados.
    private(set) var currencyCode: String = "EUR"

    // MARK: - Dependencias

    private var dependencies: AppDependencies?

    /// Inyecta las dependencias desde el entorno. Debe llamarse antes de `load()`.
    func configure(deps: AppDependencies?) {
        dependencies = deps
    }

    /// Carga (o recarga) todos los datos del panel de forma síncrona.
    func load() {
        guard let deps = dependencies else { return }

        let now = Date()
        let calendar = Calendar.current

        let subscriptionSummaries = (try? deps.subscriptions.summaries()) ?? []
        let financingSummaries = (try? deps.financings.summaries()) ?? []
        let activeSubscriptions = subscriptionSummaries.filter { $0.status == .active }
        let activeFinancings = financingSummaries.filter { $0.status == .active }

        currencyCode = activeSubscriptions.first?.currencyCode ?? "EUR"

        monthlyTotal = SpendingCalculator.monthlyTotal(
            subscriptions: subscriptionSummaries,
            financings: financingSummaries
        )
        activeSubscriptionsCount = activeSubscriptions.count
        activeFinancingsCount = activeFinancings.count

        categorySlices = SpendingCalculator.categoryBreakdown(subscriptions: subscriptionSummaries)
        evolution = SpendingCalculator.monthlyEvolution(
            subscriptions: subscriptionSummaries,
            financings: financingSummaries,
            months: 6,
            now: now,
            calendar: calendar
        )

        let insights = InsightsEngine.generate(
            subscriptions: subscriptionSummaries,
            financings: financingSummaries,
            now: now,
            calendar: calendar
        )
        potentialSaving = InsightsEngine.totalPotentialAnnualSaving(insights)

        upcomingPayments = buildUpcomingPayments(
            activeSubscriptions: activeSubscriptions,
            activeFinancings: activeFinancings,
            now: now,
            calendar: calendar
        )

        unreadNotifications = (try? deps.notifications.unreadCount()) ?? 0
    }

    // MARK: - Privado

    /// Combina la próxima renovación de cada suscripción activa con la
    /// próxima cuota de cada financiación activa, ordenado por fecha.
    private func buildUpcomingPayments(
        activeSubscriptions: [SubscriptionSummary],
        activeFinancings: [FinancingSummary],
        now: Date,
        calendar: Calendar
    ) -> [UpcomingItem] {
        var items: [UpcomingItem] = []

        for subscription in activeSubscriptions {
            let anchor = subscription.nextRenewal ?? subscription.startDate ?? subscription.createdAt
            guard let next = RecurrenceCalculator.nextRenewal(
                anchor: anchor,
                frequency: subscription.frequency,
                after: now,
                calendar: calendar
            ) else { continue }

            items.append(
                UpcomingItem(
                    id: "subscription-\(subscription.id.uuidString)",
                    name: subscription.name,
                    amount: subscription.amount,
                    currencyCode: subscription.currencyCode,
                    date: next,
                    isFinancing: false
                )
            )
        }

        for financing in activeFinancings {
            guard let next = FinancingCalculator.nextInstallmentDate(financing, calendar: calendar) else {
                continue
            }
            items.append(
                UpcomingItem(
                    id: "financing-\(financing.id.uuidString)",
                    name: financing.merchant,
                    amount: financing.monthlyAmount,
                    currencyCode: currencyCode,
                    date: next,
                    isFinancing: true
                )
            )
        }

        return Array(items.sorted { $0.date < $1.date }.prefix(5))
    }
}
