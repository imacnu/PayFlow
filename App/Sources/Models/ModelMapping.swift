import Foundation
import SubscriptionGuardianCore

// MARK: - Proyecciones de los modelos de persistencia a los resúmenes del paquete Core.

extension Subscription {
    /// Proyección inmutable usada por los cálculos del paquete Core.
    /// Es una vista "pura" del modelo: `nextRenewal` refleja la fecha
    /// almacenada, sin recalcular. Para obtener la próxima renovación real
    /// usa `nextRenewal(after:calendar:)` del modelo.
    var summary: SubscriptionSummary {
        SubscriptionSummary(
            id: id,
            name: name,
            category: category,
            amount: amount,
            currencyCode: currencyCode,
            frequency: frequency,
            nextRenewal: renewalDate,
            startDate: startDate,
            status: status,
            previousAmount: previousAmount,
            lastUsedAt: lastUsedAt,
            createdAt: createdAt
        )
    }
}

extension Financing {
    /// Proyección inmutable usada por los cálculos del paquete Core.
    var summary: FinancingSummary {
        FinancingSummary(
            id: id,
            merchant: merchant,
            provider: provider,
            totalAmount: totalAmount,
            monthlyAmount: monthlyAmount,
            totalInstallments: totalInstallments,
            paidInstallments: paidInstallments,
            firstInstallmentDate: firstInstallmentDate,
            status: status,
            interestRate: interestRate
        )
    }
}
