import Foundation

/// Categoría de servicio a la que pertenece una suscripción.
public enum ServiceCategory: String, Codable, Sendable, CaseIterable, Hashable {
    case streaming
    case ai
    case productivity
    case music
    case finance
    case fitness
    case insurance
    case membership
    case other
}

/// Frecuencia de facturación de una suscripción.
public enum BillingFrequency: String, Codable, Sendable, CaseIterable, Hashable {
    case weekly
    case monthly
    case quarterly
    case semiannual
    case annual

    /// Meses por ciclo de facturación. `nil` para frecuencia semanal,
    /// que no se expresa en meses enteros.
    public var monthsPerCycle: Int? {
        switch self {
        case .weekly: return nil
        case .monthly: return 1
        case .quarterly: return 3
        case .semiannual: return 6
        case .annual: return 12
        }
    }

    /// Número de pagos que se realizan en un año.
    public var paymentsPerYear: Decimal {
        switch self {
        case .weekly: return 52
        case .monthly: return 12
        case .quarterly: return 4
        case .semiannual: return 2
        case .annual: return 1
        }
    }
}

/// Proveedor de financiación "compra ahora, paga después" (BNPL).
public enum BNPLProvider: String, Codable, Sendable, CaseIterable, Hashable {
    case klarna
    case scalapay
    case aplazame
    case sequra
    case paypalPayIn3
    case amazonMonthly
    case custom

    /// Nombre de marca para mostrar. Son nombres propios, no se localizan.
    public var displayName: String {
        switch self {
        case .klarna: return "Klarna"
        case .scalapay: return "Scalapay"
        case .aplazame: return "Aplazame"
        case .sequra: return "SeQura"
        case .paypalPayIn3: return "PayPal Pay in 3"
        case .amazonMonthly: return "Amazon Monthly Payments"
        case .custom: return "Otro"
        }
    }
}

/// Estado actual de una suscripción.
public enum SubscriptionStatus: String, Codable, Sendable, CaseIterable, Hashable {
    case active
    case paused
    case cancelled
}

/// Estado actual de una financiación.
public enum FinancingStatus: String, Codable, Sendable, CaseIterable, Hashable {
    case active
    case completed
    case cancelled
}

/// Tipo de notificación que la app puede programar o mostrar.
public enum AppNotificationType: String, Codable, Sendable, CaseIterable, Hashable {
    case renewalUpcoming
    case installmentUpcoming
    case priceIncrease
    case unusedSubscription
}
