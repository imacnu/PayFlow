import Foundation

/// Cálculos de gasto mensual, anual y su evolución temporal.
public enum SpendingCalculator {
    // MARK: - Equivalente mensual

    /// Convierte un importe con su frecuencia al gasto mensual equivalente,
    /// redondeado a 2 decimales.
    public static func monthlyEquivalent(amount: Decimal, frequency: BillingFrequency) -> Decimal {
        switch frequency {
        case .weekly:
            // 52 semanas repartidas en 12 meses.
            return Money.rounded(Money.divide(amount * Decimal(52), by: Decimal(12)))
        case .monthly:
            return Money.rounded(amount)
        case .quarterly:
            return Money.rounded(Money.divide(amount, by: Decimal(3)))
        case .semiannual:
            return Money.rounded(Money.divide(amount, by: Decimal(6)))
        case .annual:
            return Money.rounded(Money.divide(amount, by: Decimal(12)))
        }
    }

    // MARK: - Totales

    /// Gasto mensual total de las suscripciones activas.
    public static func monthlyTotal(subscriptions: [SubscriptionSummary]) -> Decimal {
        let total = subscriptions
            .filter { $0.status == .active }
            .reduce(Decimal(0)) { partial, subscription in
                partial + monthlyEquivalent(amount: subscription.amount, frequency: subscription.frequency)
            }
        return Money.rounded(total)
    }

    /// Gasto mensual total: suscripciones activas más cuotas de
    /// financiaciones activas con plazos pendientes.
    public static func monthlyTotal(
        subscriptions: [SubscriptionSummary],
        financings: [FinancingSummary]
    ) -> Decimal {
        let financingTotal = financings
            .filter { $0.status == .active && FinancingCalculator.pendingInstallments($0) > 0 }
            .reduce(Decimal(0)) { $0 + $1.monthlyAmount }
        return Money.rounded(monthlyTotal(subscriptions: subscriptions) + financingTotal)
    }

    /// Proyección anual: gasto mensual total multiplicado por 12.
    public static func projectedAnnual(
        subscriptions: [SubscriptionSummary],
        financings: [FinancingSummary]
    ) -> Decimal {
        Money.rounded(monthlyTotal(subscriptions: subscriptions, financings: financings) * Decimal(12))
    }

    // MARK: - Desglose por categoría

    /// Porción del gasto mensual correspondiente a una categoría.
    public struct CategorySlice: Sendable, Codable, Hashable, Identifiable {
        public var id: ServiceCategory { category }
        public let category: ServiceCategory
        public let monthlyAmount: Decimal

        public init(category: ServiceCategory, monthlyAmount: Decimal) {
            self.category = category
            self.monthlyAmount = monthlyAmount
        }
    }

    /// Desglose del gasto mensual por categoría (solo suscripciones activas),
    /// ordenado de mayor a menor importe.
    public static func categoryBreakdown(subscriptions: [SubscriptionSummary]) -> [CategorySlice] {
        var totals: [ServiceCategory: Decimal] = [:]
        for subscription in subscriptions where subscription.status == .active {
            let monthly = monthlyEquivalent(amount: subscription.amount, frequency: subscription.frequency)
            totals[subscription.category, default: 0] += monthly
        }
        return totals
            .map { CategorySlice(category: $0.key, monthlyAmount: Money.rounded($0.value)) }
            .sorted { lhs, rhs in
                if lhs.monthlyAmount != rhs.monthlyAmount {
                    return lhs.monthlyAmount > rhs.monthlyAmount
                }
                // Desempate estable por nombre de categoría.
                return lhs.category.rawValue < rhs.category.rawValue
            }
    }

    // MARK: - Evolución mensual

    /// Gasto mensual estimado en un mes concreto.
    public struct MonthPoint: Sendable, Hashable {
        /// Primer instante del mes.
        public let monthStart: Date
        /// Gasto mensual total estimado de ese mes.
        public let total: Decimal

        public init(monthStart: Date, total: Decimal) {
            self.monthStart = monthStart
            self.total = total
        }
    }

    /// Evolución del gasto mensual durante los últimos `months` meses
    /// (incluido el mes actual), de más antiguo a más reciente.
    ///
    /// Para cada mes se suman:
    /// - Suscripciones no canceladas que ya existían ese mes
    ///   (`startDate ?? createdAt` anterior al fin de mes).
    /// - Financiaciones cuyo rango de cuotas cubre ese mes.
    public static func monthlyEvolution(
        subscriptions: [SubscriptionSummary],
        financings: [FinancingSummary],
        months: Int = 6,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [MonthPoint] {
        guard months > 0,
              let currentMonthStart = calendar.dateInterval(of: .month, for: now)?.start else {
            return []
        }

        var points: [MonthPoint] = []
        for offset in stride(from: months - 1, through: 0, by: -1) {
            guard let monthStart = calendar.date(byAdding: .month, value: -offset, to: currentMonthStart),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
                continue
            }

            var total = Decimal(0)

            for subscription in subscriptions where subscription.status != .cancelled {
                let existsSince = subscription.startDate ?? subscription.createdAt
                if existsSince < monthEnd {
                    total += monthlyEquivalent(amount: subscription.amount, frequency: subscription.frequency)
                }
            }

            for financing in financings {
                guard let firstDate = financing.firstInstallmentDate,
                      financing.totalInstallments > 0,
                      firstDate < monthEnd,
                      let lastExclusive = calendar.date(
                        byAdding: .month,
                        value: financing.totalInstallments,
                        to: firstDate
                      ),
                      lastExclusive > monthStart else {
                    continue
                }
                total += financing.monthlyAmount
            }

            points.append(MonthPoint(monthStart: monthStart, total: Money.rounded(total)))
        }
        return points
    }

    /// Variación porcentual del último mes respecto al anterior,
    /// redondeada a 2 decimales. `nil` si no hay al menos dos puntos
    /// o el mes anterior fue 0.
    public static func monthOverMonthVariation(evolution: [MonthPoint]) -> Decimal? {
        guard evolution.count >= 2 else { return nil }
        let previous = evolution[evolution.count - 2].total
        let last = evolution[evolution.count - 1].total
        guard previous != 0 else { return nil }
        let variation = Money.divide((last - previous) * Decimal(100), by: previous)
        return Money.rounded(variation)
    }
}
