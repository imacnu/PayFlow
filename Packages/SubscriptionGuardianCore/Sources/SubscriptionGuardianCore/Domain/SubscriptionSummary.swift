import Foundation

/// Resumen inmutable de una suscripción, usado por los cálculos del paquete.
/// Es una proyección de los modelos de persistencia de la app.
public struct SubscriptionSummary: Sendable, Codable, Hashable, Identifiable {
    /// Identificador único de la suscripción.
    public let id: UUID
    /// Nombre del servicio (p. ej. "Netflix").
    public let name: String
    /// Categoría del servicio.
    public let category: ServiceCategory
    /// Importe de cada cargo, en la divisa indicada.
    public let amount: Decimal
    /// Código ISO 4217 de la divisa (p. ej. "EUR").
    public let currencyCode: String
    /// Frecuencia de facturación.
    public let frequency: BillingFrequency
    /// Fecha de la próxima renovación, si se conoce.
    public let nextRenewal: Date?
    /// Fecha de alta del servicio, si se conoce.
    public let startDate: Date?
    /// Estado actual de la suscripción.
    public let status: SubscriptionStatus
    /// Importe anterior, si ha habido un cambio de precio.
    public let previousAmount: Decimal?
    /// Última vez que el usuario indicó haber usado el servicio.
    public let lastUsedAt: Date?
    /// Fecha de creación del registro en la app.
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        category: ServiceCategory,
        amount: Decimal,
        currencyCode: String = "EUR",
        frequency: BillingFrequency = .monthly,
        nextRenewal: Date? = nil,
        startDate: Date? = nil,
        status: SubscriptionStatus = .active,
        previousAmount: Decimal? = nil,
        lastUsedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.amount = amount
        self.currencyCode = currencyCode
        self.frequency = frequency
        self.nextRenewal = nextRenewal
        self.startDate = startDate
        self.status = status
        self.previousAmount = previousAmount
        self.lastUsedAt = lastUsedAt
        self.createdAt = createdAt
    }
}
