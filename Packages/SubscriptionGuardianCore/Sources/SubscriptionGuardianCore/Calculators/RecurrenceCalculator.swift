import Foundation

/// Cálculo de fechas de renovación a partir de una fecha ancla
/// y una frecuencia de facturación.
public enum RecurrenceCalculator {
    /// Límite de iteraciones para evitar bucles infinitos con datos corruptos.
    private static let maxIterations = 1000

    /// Componentes de calendario que representan un ciclo de la frecuencia dada.
    public static func dateComponents(for frequency: BillingFrequency) -> DateComponents {
        switch frequency {
        case .weekly: return DateComponents(weekOfYear: 1)
        case .monthly: return DateComponents(month: 1)
        case .quarterly: return DateComponents(month: 3)
        case .semiannual: return DateComponents(month: 6)
        case .annual: return DateComponents(year: 1)
        }
    }

    /// Próxima renovación estrictamente posterior a `reference`.
    ///
    /// Si la fecha ancla ya es futura respecto a `reference`, se devuelve tal cual.
    /// En otro caso se avanza ciclo a ciclo desde el ancla (máximo 1000 iteraciones).
    /// Devuelve `nil` si el calendario no puede calcular la fecha.
    public static func nextRenewal(
        anchor: Date,
        frequency: BillingFrequency,
        after reference: Date,
        calendar: Calendar = .current
    ) -> Date? {
        if anchor > reference {
            return anchor
        }
        let step = dateComponents(for: frequency)
        var current = anchor
        var iterations = 0
        while current <= reference {
            iterations += 1
            if iterations > maxIterations {
                return nil
            }
            guard let next = calendar.date(byAdding: step, to: current) else {
                return nil
            }
            current = next
        }
        return current
    }

    /// Todas las renovaciones que caen dentro del intervalo dado.
    ///
    /// Se avanza desde el ancla ciclo a ciclo (máximo 1000 iteraciones en total).
    public static func renewals(
        anchor: Date,
        frequency: BillingFrequency,
        in interval: DateInterval,
        calendar: Calendar = .current
    ) -> [Date] {
        let step = dateComponents(for: frequency)
        var current = anchor
        var iterations = 0
        var result: [Date] = []

        while current <= interval.end {
            if current >= interval.start {
                result.append(current)
            }
            iterations += 1
            if iterations > maxIterations {
                break
            }
            guard let next = calendar.date(byAdding: step, to: current) else {
                break
            }
            current = next
        }
        return result
    }
}
