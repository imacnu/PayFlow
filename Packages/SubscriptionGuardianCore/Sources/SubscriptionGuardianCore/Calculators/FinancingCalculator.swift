import Foundation

/// Cálculos sobre el estado de una financiación BNPL.
public enum FinancingCalculator {
    /// Número de cuotas pendientes (nunca negativo).
    public static func pendingInstallments(_ financing: FinancingSummary) -> Int {
        max(0, financing.totalInstallments - financing.paidInstallments)
    }

    /// Capital pendiente: cuota mensual por cuotas pendientes, redondeado.
    public static func pendingCapital(_ financing: FinancingSummary) -> Decimal {
        let pending = pendingInstallments(financing)
        return Money.rounded(financing.monthlyAmount * Decimal(pending))
    }

    /// Fecha de la próxima cuota: primera cuota más las cuotas ya pagadas en meses.
    /// `nil` si no hay fecha de primera cuota, la financiación no está activa
    /// o no quedan cuotas pendientes.
    public static func nextInstallmentDate(
        _ financing: FinancingSummary,
        calendar: Calendar = .current
    ) -> Date? {
        guard let firstDate = financing.firstInstallmentDate,
              financing.status == .active,
              pendingInstallments(financing) > 0 else {
            return nil
        }
        return calendar.date(byAdding: .month, value: financing.paidInstallments, to: firstDate)
    }

    /// Fecha de la última cuota: primera cuota más (total − 1) meses.
    public static func endDate(
        _ financing: FinancingSummary,
        calendar: Calendar = .current
    ) -> Date? {
        guard let firstDate = financing.firstInstallmentDate,
              financing.totalInstallments > 0 else {
            return nil
        }
        return calendar.date(byAdding: .month, value: financing.totalInstallments - 1, to: firstDate)
    }

    /// Progreso de pago entre 0 y 1 (0 si no hay cuotas).
    public static func progress(_ financing: FinancingSummary) -> Double {
        guard financing.totalInstallments > 0 else { return 0 }
        let ratio = Double(financing.paidInstallments) / Double(financing.totalInstallments)
        return min(max(ratio, 0), 1)
    }

    /// Indica si la financiación está activa y a punto de terminar
    /// (quedan una o dos cuotas).
    public static func isAlmostFinished(_ financing: FinancingSummary) -> Bool {
        let pending = pendingInstallments(financing)
        return financing.status == .active && pending > 0 && pending <= 2
    }

    /// Número de cuotas devengadas: aquellas cuya fecha de vencimiento
    /// (primera cuota más N meses) es anterior o igual a `asOf`.
    /// Las cuotas devengadas se consideran pagadas automáticamente.
    public static func accruedInstallments(
        firstInstallmentDate: Date,
        totalInstallments: Int,
        asOf: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        guard totalInstallments > 0 else { return 0 }
        let start = calendar.startOfDay(for: firstInstallmentDate)
        let today = calendar.startOfDay(for: asOf)
        guard start <= today else { return 0 }
        let months = calendar.dateComponents([.month], from: start, to: today).month ?? 0
        return min(totalInstallments, months + 1)
    }
}
