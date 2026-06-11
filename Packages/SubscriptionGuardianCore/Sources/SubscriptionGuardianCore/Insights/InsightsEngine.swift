import Foundation

/// Motor de heurísticas que genera hallazgos a partir de
/// suscripciones y financiaciones.
public enum InsightsEngine {
    /// Días sin uso (o desde el alta) para considerar una suscripción olvidada.
    private static let unusedThresholdDays = 60
    /// Categorías donde tener varios servicios suele ser redundante.
    private static let overlapCategories: [ServiceCategory] = [.streaming, .music, .ai]
    /// Umbral (fracción del total) para considerar una categoría dominante.
    private static let dominantThreshold = Decimal(string: "0.4") ?? 0

    /// Genera la lista de hallazgos ordenada: primero los que tienen
    /// ahorro anual estimado (de mayor a menor) y después el resto.
    public static func generate(
        subscriptions: [SubscriptionSummary],
        financings: [FinancingSummary],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [Insight] {
        var insights: [Insight] = []
        let activeSubscriptions = subscriptions.filter { $0.status == .active }

        insights.append(contentsOf: duplicateCategoryInsights(activeSubscriptions))
        insights.append(contentsOf: unusedInsights(activeSubscriptions, now: now, calendar: calendar))
        insights.append(contentsOf: priceIncreaseInsights(activeSubscriptions))
        insights.append(contentsOf: almostDoneInsights(financings, calendar: calendar))
        insights.append(contentsOf: dominantCategoryInsights(activeSubscriptions))

        // Orden: con ahorro estimado primero (descendente), el resto detrás
        // conservando el orden de generación.
        let withSaving = insights
            .filter { $0.estimatedAnnualSaving != nil }
            .sorted { ($0.estimatedAnnualSaving ?? 0) > ($1.estimatedAnnualSaving ?? 0) }
        let withoutSaving = insights.filter { $0.estimatedAnnualSaving == nil }
        return withSaving + withoutSaving
    }

    /// Suma de los ahorros anuales estimados de todos los hallazgos.
    public static func totalPotentialAnnualSaving(_ insights: [Insight]) -> Decimal {
        let total = insights.reduce(Decimal(0)) { $0 + ($1.estimatedAnnualSaving ?? 0) }
        return Money.rounded(total)
    }

    // MARK: - Heurísticas

    /// Dos o más suscripciones activas en la misma categoría redundante.
    private static func duplicateCategoryInsights(_ subscriptions: [SubscriptionSummary]) -> [Insight] {
        var insights: [Insight] = []
        for category in overlapCategories {
            let inCategory = subscriptions
                .filter { $0.category == category }
                .sorted { lhs, rhs in
                    monthlyCost(lhs) > monthlyCost(rhs)
                }
            guard inCategory.count >= 2, let cheapest = inCategory.last else { continue }
            let saving = Money.rounded(monthlyCost(cheapest) * Decimal(12))
            insights.append(
                Insight(
                    id: "\(Insight.Kind.duplicateCategory.rawValue)-\(category.rawValue)",
                    kind: .duplicateCategory,
                    subscriptionNames: inCategory.map(\.name),
                    category: category,
                    estimatedAnnualSaving: saving
                )
            )
        }
        return insights
    }

    /// Suscripciones antiguas que no se usan desde hace más de 60 días.
    private static func unusedInsights(
        _ subscriptions: [SubscriptionSummary],
        now: Date,
        calendar: Calendar
    ) -> [Insight] {
        guard let threshold = calendar.date(byAdding: .day, value: -unusedThresholdDays, to: now) else {
            return []
        }
        return subscriptions.compactMap { subscription in
            guard subscription.createdAt < threshold else { return nil }
            if let lastUsed = subscription.lastUsedAt, lastUsed >= threshold {
                return nil
            }
            let saving = Money.rounded(monthlyCost(subscription) * Decimal(12))
            return Insight(
                id: "\(Insight.Kind.unusedSubscription.rawValue)-\(subscription.id.uuidString)",
                kind: .unusedSubscription,
                subscriptionNames: [subscription.name],
                category: subscription.category,
                estimatedAnnualSaving: saving,
                referenceDate: subscription.lastUsedAt
            )
        }
    }

    /// Suscripciones cuyo precio ha subido. `amount` es la subida anualizada.
    private static func priceIncreaseInsights(_ subscriptions: [SubscriptionSummary]) -> [Insight] {
        subscriptions.compactMap { subscription in
            guard let previous = subscription.previousAmount,
                  subscription.amount > previous else {
                return nil
            }
            let monthlyDelta = SpendingCalculator.monthlyEquivalent(
                amount: subscription.amount - previous,
                frequency: subscription.frequency
            )
            let annualizedIncrease = Money.rounded(monthlyDelta * Decimal(12))
            return Insight(
                id: "\(Insight.Kind.priceIncrease.rawValue)-\(subscription.id.uuidString)",
                kind: .priceIncrease,
                subscriptionNames: [subscription.name],
                category: subscription.category,
                amount: annualizedIncrease
            )
        }
    }

    /// Financiaciones a punto de terminar.
    private static func almostDoneInsights(
        _ financings: [FinancingSummary],
        calendar: Calendar
    ) -> [Insight] {
        financings.compactMap { financing in
            guard FinancingCalculator.isAlmostFinished(financing) else { return nil }
            return Insight(
                id: "\(Insight.Kind.financingAlmostDone.rawValue)-\(financing.id.uuidString)",
                kind: .financingAlmostDone,
                subscriptionNames: [financing.merchant],
                amount: financing.monthlyAmount,
                referenceDate: FinancingCalculator.endDate(financing, calendar: calendar)
            )
        }
    }

    /// Categoría que supera el 40 % del gasto mensual total.
    /// `amount` es el porcentaje (0–100) redondeado.
    private static func dominantCategoryInsights(_ subscriptions: [SubscriptionSummary]) -> [Insight] {
        let breakdown = SpendingCalculator.categoryBreakdown(subscriptions: subscriptions)
        guard let top = breakdown.first else { return [] }
        let total = breakdown.reduce(Decimal(0)) { $0 + $1.monthlyAmount }
        guard total > 0 else { return [] }
        let share = Money.divide(top.monthlyAmount, by: total)
        guard share > dominantThreshold else { return [] }
        let percentage = Money.rounded(share * Decimal(100))
        let names = subscriptions
            .filter { $0.category == top.category }
            .sorted { monthlyCost($0) > monthlyCost($1) }
            .map(\.name)
        return [
            Insight(
                id: "\(Insight.Kind.dominantCategory.rawValue)-\(top.category.rawValue)",
                kind: .dominantCategory,
                subscriptionNames: names,
                category: top.category,
                amount: percentage
            )
        ]
    }

    /// Coste mensual equivalente de una suscripción.
    private static func monthlyCost(_ subscription: SubscriptionSummary) -> Decimal {
        SpendingCalculator.monthlyEquivalent(
            amount: subscription.amount,
            frequency: subscription.frequency
        )
    }
}
