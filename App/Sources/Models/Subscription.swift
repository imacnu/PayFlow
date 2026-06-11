import Foundation
import SwiftData
import SubscriptionGuardianCore

/// Suscripción recurrente del usuario (Netflix, Spotify, etc.).
/// Modelo compatible con CloudKit: sin atributos únicos, todas las propiedades
/// con valor por defecto u opcionales y relaciones opcionales.
@Model
final class Subscription {
    /// Identificador único de la suscripción.
    var id: UUID = UUID()
    /// Nombre del servicio (p. ej. "Netflix").
    var name: String = ""
    /// Categoría del servicio, almacenada como cadena cruda.
    var categoryRaw: String = ServiceCategory.other.rawValue
    /// Proveedor o empresa que factura el servicio.
    var provider: String = ""
    /// Importe de cada cargo, en la divisa indicada.
    var amount: Decimal = 0
    /// Importe anterior, si ha habido un cambio de precio.
    var previousAmount: Decimal?
    /// Código ISO 4217 de la divisa (p. ej. "EUR").
    var currencyCode: String = "EUR"
    /// Frecuencia de facturación, almacenada como cadena cruda.
    var frequencyRaw: String = BillingFrequency.monthly.rawValue
    /// Fecha de la próxima renovación conocida.
    var renewalDate: Date?
    /// Fecha de alta del servicio.
    var startDate: Date?
    /// Días de antelación elegidos para los recordatorios.
    var reminderDaysBefore: Int = 3
    /// Notas libres del usuario.
    var notes: String = ""
    /// Símbolo SF del icono.
    var iconSymbol: String = "sparkles"
    /// Color de marca en hexadecimal "RRGGBB".
    var colorHex: String = "1F6FEB"
    /// Monograma de respaldo cuando no hay icono.
    var monogram: String = ""
    /// Estado de la suscripción, almacenado como cadena cruda.
    var statusRaw: String = SubscriptionStatus.active.rawValue
    /// Última vez que el usuario indicó haber usado el servicio.
    var lastUsedAt: Date?
    /// Fecha de creación del registro.
    var createdAt: Date = Date()
    /// Usuario propietario. Relación opcional por compatibilidad con CloudKit.
    var owner: User?

    /// Acceso tipado a la categoría (no persistido).
    var category: ServiceCategory {
        get { ServiceCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    /// Acceso tipado a la frecuencia (no persistido).
    var frequency: BillingFrequency {
        get { BillingFrequency(rawValue: frequencyRaw) ?? .monthly }
        set { frequencyRaw = newValue.rawValue }
    }

    /// Acceso tipado al estado (no persistido).
    var status: SubscriptionStatus {
        get { SubscriptionStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    /// Próxima renovación estrictamente posterior a `reference`, calculada
    /// con `RecurrenceCalculator` usando como ancla la fecha de renovación,
    /// la de alta o la de creación (en ese orden de preferencia).
    func nextRenewal(after reference: Date = Date(), calendar: Calendar = .current) -> Date? {
        let anchor = renewalDate ?? startDate ?? createdAt
        return RecurrenceCalculator.nextRenewal(
            anchor: anchor,
            frequency: frequency,
            after: reference,
            calendar: calendar
        )
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        category: ServiceCategory = .other,
        provider: String = "",
        amount: Decimal = 0,
        previousAmount: Decimal? = nil,
        currencyCode: String = "EUR",
        frequency: BillingFrequency = .monthly,
        renewalDate: Date? = nil,
        startDate: Date? = nil,
        reminderDaysBefore: Int = 3,
        notes: String = "",
        iconSymbol: String = "sparkles",
        colorHex: String = "1F6FEB",
        monogram: String = "",
        status: SubscriptionStatus = .active,
        lastUsedAt: Date? = nil,
        createdAt: Date = Date(),
        owner: User? = nil
    ) {
        self.id = id
        self.name = name
        self.categoryRaw = category.rawValue
        self.provider = provider
        self.amount = amount
        self.previousAmount = previousAmount
        self.currencyCode = currencyCode
        self.frequencyRaw = frequency.rawValue
        self.renewalDate = renewalDate
        self.startDate = startDate
        self.reminderDaysBefore = reminderDaysBefore
        self.notes = notes
        self.iconSymbol = iconSymbol
        self.colorHex = colorHex
        self.monogram = monogram
        self.statusRaw = status.rawValue
        self.lastUsedAt = lastUsedAt
        self.createdAt = createdAt
        self.owner = owner
    }
}
