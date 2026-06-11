import Foundation
import WidgetKit
import SubscriptionGuardianCore

/// Publica en el App Group la instantánea de datos que consumen los widgets
/// y pide a WidgetKit que recargue sus líneas de tiempo.
@MainActor
final class WidgetSnapshotWriter {
    /// Construye y escribe la instantánea actual.
    func write(
        subscriptions: [SubscriptionSummary],
        financings: [FinancingSummary],
        isPremium: Bool
    ) {
        let now = Date()
        let activeSubscriptions = subscriptions.filter { $0.status == .active }
        let activeFinancings = financings.filter { $0.status == .active }

        // Próximos cargos: una renovación por suscripción activa
        // y una cuota por financiación activa, ordenados por fecha.
        var payments: [UpcomingPayment] = []
        for subscription in activeSubscriptions {
            let anchor = subscription.nextRenewal ?? subscription.startDate ?? subscription.createdAt
            guard let nextDate = RecurrenceCalculator.nextRenewal(
                anchor: anchor,
                frequency: subscription.frequency,
                after: now
            ) else { continue }
            payments.append(
                UpcomingPayment(
                    id: subscription.id,
                    name: subscription.name,
                    amount: subscription.amount,
                    currencyCode: subscription.currencyCode,
                    date: nextDate,
                    kindRaw: "subscription"
                )
            )
        }
        for financing in activeFinancings {
            guard let nextDate = FinancingCalculator.nextInstallmentDate(financing) else { continue }
            payments.append(
                UpcomingPayment(
                    id: financing.id,
                    name: financing.merchant,
                    amount: financing.monthlyAmount,
                    currencyCode: "EUR",
                    date: nextDate,
                    kindRaw: "financing"
                )
            )
        }
        let nextPayments = Array(payments.sorted { $0.date < $1.date }.prefix(6))

        let snapshot = WidgetSnapshot(
            generatedAt: now,
            monthlyTotal: SpendingCalculator.monthlyTotal(
                subscriptions: subscriptions,
                financings: financings
            ),
            currencyCode: activeSubscriptions.first?.currencyCode ?? "EUR",
            activeSubscriptions: activeSubscriptions.count,
            activeFinancings: activeFinancings.count,
            isPremium: isPremium,
            nextPayments: nextPayments,
            categoryBreakdown: SpendingCalculator.categoryBreakdown(subscriptions: subscriptions)
        )

        guard let data = snapshot.encoded(),
              let defaults = UserDefaults(suiteName: AppConfig.appGroupID) else {
            return
        }
        defaults.set(data, forKey: AppConfig.widgetSnapshotKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
