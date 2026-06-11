import Foundation
import SwiftData
import SubscriptionGuardianCore

/// Borrador editable de una suscripción, usado por los formularios de alta y edición.
struct SubscriptionDraft {
    var name: String = ""
    var category: ServiceCategory = .other
    var provider: String = ""
    var amount: Decimal = 0
    var currencyCode: String = "EUR"
    var frequency: BillingFrequency = .monthly
    var renewalDate: Date?
    var startDate: Date?
    var reminderDaysBefore: Int = 3
    var notes: String = ""
    var iconSymbol: String = "sparkles"
    var colorHex: String = "1F6FEB"
    var monogram: String = ""

    /// Crea un borrador precargado desde una plantilla del catálogo de servicios.
    static func from(template: ServiceTemplate) -> SubscriptionDraft {
        var draft = SubscriptionDraft()
        draft.name = template.name
        draft.category = template.category
        draft.amount = template.suggestedMonthlyPrice ?? 0
        draft.iconSymbol = template.symbol ?? "sparkles"
        draft.colorHex = template.colorHex
        draft.monogram = template.monogram
        return draft
    }
}

/// Contrato del repositorio de suscripciones.
@MainActor
protocol SubscriptionRepositoryProtocol: AnyObject {
    func all() throws -> [Subscription]
    func active() throws -> [Subscription]
    func create(from draft: SubscriptionDraft) throws -> Subscription
    func update(_ sub: Subscription, with draft: SubscriptionDraft) throws
    func setStatus(_ sub: Subscription, status: SubscriptionStatus) throws
    func markUsed(_ sub: Subscription) throws
    func delete(_ sub: Subscription) throws
    func summaries() throws -> [SubscriptionSummary]
}

/// Repositorio de suscripciones respaldado por SwiftData.
@MainActor
final class SwiftDataSubscriptionRepository: SubscriptionRepositoryProtocol {
    private let context: ModelContext
    private let entitlements: EntitlementStore

    /// Callback invocado tras cada mutación; la capa de DI lo conecta con la
    /// escritura del snapshot del widget y la reprogramación de notificaciones.
    var onChange: @MainActor () -> Void

    init(
        context: ModelContext,
        entitlements: EntitlementStore,
        onChange: @escaping @MainActor () -> Void = {}
    ) {
        self.context = context
        self.entitlements = entitlements
        self.onChange = onChange
    }

    func all() throws -> [Subscription] {
        let descriptor = FetchDescriptor<Subscription>(
            sortBy: [SortDescriptor(\Subscription.name)]
        )
        return try context.fetch(descriptor)
    }

    /// Suscripciones activas. El filtrado se hace en memoria: los predicados
    /// sobre enums/propiedades calculadas son frágiles y las colecciones son pequeñas.
    func active() throws -> [Subscription] {
        try all().filter { $0.statusRaw == SubscriptionStatus.active.rawValue }
    }

    func create(from draft: SubscriptionDraft) throws -> Subscription {
        let currentCount = try all().count
        guard entitlements.canAddSubscription(currentCount: currentCount) else {
            throw RepositoryError.freeTierLimitReached(kind: .subscriptions)
        }
        let subscription = Subscription()
        apply(draft, to: subscription)
        context.insert(subscription)
        try context.save()
        onChange()
        return subscription
    }

    func update(_ sub: Subscription, with draft: SubscriptionDraft) throws {
        // Detección de cambio de precio: conservamos el importe anterior
        // para poder avisar al usuario de subidas.
        if draft.amount != sub.amount {
            sub.previousAmount = sub.amount
        }
        apply(draft, to: sub)
        try context.save()
        onChange()
    }

    func setStatus(_ sub: Subscription, status: SubscriptionStatus) throws {
        sub.status = status
        try context.save()
        onChange()
    }

    func markUsed(_ sub: Subscription) throws {
        sub.lastUsedAt = Date()
        try context.save()
        onChange()
    }

    func delete(_ sub: Subscription) throws {
        context.delete(sub)
        try context.save()
        onChange()
    }

    func summaries() throws -> [SubscriptionSummary] {
        try all().map { $0.summary }
    }

    // MARK: - Privado

    /// Vuelca los campos del borrador en el modelo.
    private func apply(_ draft: SubscriptionDraft, to sub: Subscription) {
        sub.name = draft.name
        sub.category = draft.category
        sub.provider = draft.provider
        sub.amount = draft.amount
        sub.currencyCode = draft.currencyCode
        sub.frequency = draft.frequency
        sub.renewalDate = draft.renewalDate
        sub.startDate = draft.startDate
        sub.reminderDaysBefore = draft.reminderDaysBefore
        sub.notes = draft.notes
        sub.iconSymbol = draft.iconSymbol
        sub.colorHex = draft.colorHex
        sub.monogram = draft.monogram
    }
}
