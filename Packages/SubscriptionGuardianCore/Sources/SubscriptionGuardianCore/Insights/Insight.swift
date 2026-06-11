import Foundation

/// Hallazgo sobre los gastos del usuario. Contiene solo datos semánticos:
/// los textos visibles los construye y localiza la capa de UI.
public struct Insight: Sendable, Hashable, Identifiable {
    /// Tipo de hallazgo.
    public enum Kind: String, Sendable, Codable {
        case duplicateCategory
        case unusedSubscription
        case priceIncrease
        case financingAlmostDone
        case dominantCategory
    }

    /// Identificador estable: "\(kind)-\(uuid o categoría relevante)".
    public let id: String
    /// Tipo de hallazgo.
    public let kind: Kind
    /// Nombres de suscripciones o comercios implicados.
    public let subscriptionNames: [String]
    /// Categoría relevante, si aplica.
    public let category: ServiceCategory?
    /// Dato principal (p. ej. subida anualizada, cuota mensual, % de categoría).
    public let amount: Decimal?
    /// Ahorro anual estimado si el usuario actúa, si aplica.
    public let estimatedAnnualSaving: Decimal?
    /// Fecha de referencia (p. ej. fin de una financiación), si aplica.
    public let referenceDate: Date?

    public init(
        id: String,
        kind: Kind,
        subscriptionNames: [String] = [],
        category: ServiceCategory? = nil,
        amount: Decimal? = nil,
        estimatedAnnualSaving: Decimal? = nil,
        referenceDate: Date? = nil
    ) {
        self.id = id
        self.kind = kind
        self.subscriptionNames = subscriptionNames
        self.category = category
        self.amount = amount
        self.estimatedAnnualSaving = estimatedAnnualSaving
        self.referenceDate = referenceDate
    }
}
