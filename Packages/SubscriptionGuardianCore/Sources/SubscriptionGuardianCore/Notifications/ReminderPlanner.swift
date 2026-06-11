import Foundation

/// Recordatorio planificado, listo para convertirse en una
/// solicitud de notificación local en la capa de la app.
public struct PlannedReminder: Sendable, Hashable {
    /// Tipo de evento que recuerda.
    public enum Kind: String, Sendable {
        case subscriptionRenewal
        case financingInstallment
    }

    /// Identificador estable: "sub-<uuid>-<offset>" o "fin-<uuid>-<offset>".
    public let identifier: String
    /// Tipo de recordatorio.
    public let kind: Kind
    /// Identificador de la suscripción o financiación.
    public let entityID: UUID
    /// Nombre del servicio o comercio.
    public let entityName: String
    /// Importe del cargo.
    public let amount: Decimal
    /// Código ISO 4217 de la divisa.
    public let currencyCode: String
    /// Fecha del cargo.
    public let eventDate: Date
    /// Momento de disparo: `offsetDays` días antes, a las 09:00 locales.
    public let fireDate: Date
    /// Días de antelación respecto al cargo.
    public let offsetDays: Int

    public init(
        identifier: String,
        kind: Kind,
        entityID: UUID,
        entityName: String,
        amount: Decimal,
        currencyCode: String,
        eventDate: Date,
        fireDate: Date,
        offsetDays: Int
    ) {
        self.identifier = identifier
        self.kind = kind
        self.entityID = entityID
        self.entityName = entityName
        self.amount = amount
        self.currencyCode = currencyCode
        self.eventDate = eventDate
        self.fireDate = fireDate
        self.offsetDays = offsetDays
    }
}

/// Planificador de recordatorios de renovaciones y cuotas.
public enum ReminderPlanner {
    /// Antelaciones estándar disponibles, en días.
    public static let standardOffsets = [1, 3, 7, 15]
    /// Antelaciones fijas para cuotas de financiación.
    private static let financingOffsets = [1, 3]
    /// Antelación por defecto para suscripciones sin preferencia.
    private static let defaultReminderDays = 3
    /// Hora local de disparo de los recordatorios.
    private static let fireHour = 9

    /// Planifica los recordatorios dentro de la ventana dada, ordenados por
    /// fecha de disparo y limitados a `maxRequests`.
    ///
    /// - Parameters:
    ///   - reminderDays: antelación máxima elegida por el usuario para cada
    ///     suscripción (por defecto 3 días).
    public static func plan(
        subscriptions: [SubscriptionSummary],
        reminderDays: [UUID: Int],
        financings: [FinancingSummary],
        now: Date = Date(),
        windowDays: Int = 45,
        maxRequests: Int = 60,
        calendar: Calendar = .current
    ) -> [PlannedReminder] {
        guard maxRequests > 0,
              let windowEnd = calendar.date(byAdding: .day, value: windowDays, to: now),
              windowEnd > now else {
            return []
        }
        let window = DateInterval(start: now, end: windowEnd)
        var reminders: [PlannedReminder] = []

        // Renovaciones de suscripciones activas.
        for subscription in subscriptions where subscription.status == .active {
            guard let anchor = subscription.nextRenewal ?? subscription.startDate else { continue }
            let renewals = RecurrenceCalculator.renewals(
                anchor: anchor,
                frequency: subscription.frequency,
                in: window,
                calendar: calendar
            )
            let maxOffset = reminderDays[subscription.id] ?? defaultReminderDays
            let offsets = standardOffsets.filter { $0 <= maxOffset }

            for eventDate in renewals {
                for offset in offsets {
                    if let reminder = makeReminder(
                        prefix: "sub",
                        kind: .subscriptionRenewal,
                        entityID: subscription.id,
                        entityName: subscription.name,
                        amount: subscription.amount,
                        currencyCode: subscription.currencyCode,
                        eventDate: eventDate,
                        offset: offset,
                        now: now,
                        calendar: calendar
                    ) {
                        reminders.append(reminder)
                    }
                }
            }
        }

        // Cuotas de financiaciones activas.
        for financing in financings where financing.status == .active {
            guard let firstDate = financing.firstInstallmentDate,
                  financing.paidInstallments < financing.totalInstallments else {
                continue
            }
            for index in financing.paidInstallments..<financing.totalInstallments {
                guard let eventDate = calendar.date(byAdding: .month, value: index, to: firstDate) else {
                    continue
                }
                guard eventDate > now, eventDate <= windowEnd else { continue }
                for offset in financingOffsets {
                    if let reminder = makeReminder(
                        prefix: "fin",
                        kind: .financingInstallment,
                        entityID: financing.id,
                        entityName: financing.merchant,
                        amount: financing.monthlyAmount,
                        currencyCode: "EUR",
                        eventDate: eventDate,
                        offset: offset,
                        now: now,
                        calendar: calendar
                    ) {
                        reminders.append(reminder)
                    }
                }
            }
        }

        return Array(
            reminders
                .sorted { $0.fireDate < $1.fireDate }
                .prefix(maxRequests)
        )
    }

    /// Construye un recordatorio si su fecha de disparo es futura.
    private static func makeReminder(
        prefix: String,
        kind: PlannedReminder.Kind,
        entityID: UUID,
        entityName: String,
        amount: Decimal,
        currencyCode: String,
        eventDate: Date,
        offset: Int,
        now: Date,
        calendar: Calendar
    ) -> PlannedReminder? {
        guard let reminderDay = calendar.date(byAdding: .day, value: -offset, to: eventDate),
              let fireDate = calendar.date(
                bySettingHour: fireHour,
                minute: 0,
                second: 0,
                of: reminderDay
              ),
              fireDate > now else {
            return nil
        }
        return PlannedReminder(
            identifier: "\(prefix)-\(entityID.uuidString)-\(offset)",
            kind: kind,
            entityID: entityID,
            entityName: entityName,
            amount: amount,
            currencyCode: currencyCode,
            eventDate: eventDate,
            fireDate: fireDate,
            offsetDays: offset
        )
    }
}
