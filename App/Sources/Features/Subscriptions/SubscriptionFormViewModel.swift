//
//  SubscriptionFormViewModel.swift
//  Subscription Guardian
//
//  Estado y validación del formulario de alta y edición de suscripciones.
//

import Foundation
import Observation
import SubscriptionGuardianCore

/// Modo del formulario de suscripción: alta o edición de una existente.
enum SubscriptionFormMode {
    case create
    case edit(Subscription)
}

/// ViewModel del formulario de suscripciones.
@MainActor
@Observable
final class SubscriptionFormViewModel {
    /// Dependencias inyectadas desde la vista vía `configure(deps:)`.
    private var deps: AppDependencies?

    let mode: SubscriptionFormMode

    // MARK: - Campos del formulario

    var name = ""
    var category: ServiceCategory = .other
    var provider = ""
    /// Importe como texto; se admite coma o punto como separador decimal.
    var amountText = ""
    var currencyCode = "EUR"
    var frequency: BillingFrequency = .monthly
    var hasRenewalDate = false
    var renewalDate = Date()
    var reminderDaysBefore = 3
    var iconSymbol = "sparkles"
    var colorHex = "1F6FEB"
    var monogram = ""
    var notes = ""

    /// Fecha de alta preservada al editar (no se edita en el formulario).
    private var startDate: Date?

    // MARK: - Estado de la vista

    /// Presenta el paywall cuando se alcanza el límite del plan gratuito.
    var showPaywall = false
    /// Mensaje de error de guardado, si lo hay.
    var errorMessage: String?

    /// Divisas seleccionables en el formulario.
    static let currencyOptions = ["EUR", "USD", "GBP"]
    /// Opciones de días de antelación del recordatorio.
    static let reminderOptions = [1, 3, 7, 15]
    /// Símbolos SF seleccionables para el icono.
    static let symbolOptions = [
        "sparkles", "play.tv.fill", "music.note", "gamecontroller.fill",
        "cloud.fill", "book.fill", "figure.run", "newspaper.fill"
    ]
    /// Colores hexadecimales seleccionables.
    static let colorOptions = [
        "1F6FEB", "E50914", "1DB954", "FF9500",
        "AF52DE", "FF2D55", "30B0C7", "8E8E93"
    ]

    init(mode: SubscriptionFormMode = .create) {
        self.mode = mode
        if case .edit(let subscription) = mode {
            populate(from: subscription)
        }
    }

    /// Inyecta las dependencias de la app. Debe llamarse desde `.task`/onAppear.
    func configure(deps: AppDependencies?) {
        self.deps = deps
    }

    // MARK: - Validación

    /// Importe parseado del texto, aceptando coma decimal.
    var parsedAmount: Decimal? {
        Decimal(string: amountText.replacingOccurrences(of: ",", with: "."))
    }

    /// El formulario es válido si hay nombre y un importe mayor que cero.
    var isValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, let amount = parsedAmount else { return false }
        return amount > 0
    }

    /// Indica si el formulario está en modo edición.
    var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    // MARK: - Plantillas

    /// Precarga los campos desde una plantilla del catálogo de servicios.
    /// El precio no se precarga: lo introduce el usuario manualmente.
    func apply(template: ServiceTemplate) {
        let draft = SubscriptionDraft.from(template: template)
        name = draft.name
        category = draft.category
        iconSymbol = draft.iconSymbol
        colorHex = draft.colorHex
        monogram = draft.monogram
    }

    // MARK: - Guardado

    /// Guarda la suscripción. Devuelve `true` si se guardó correctamente.
    func save() -> Bool {
        guard let deps, let amount = parsedAmount, isValid else { return false }

        var draft = SubscriptionDraft()
        draft.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.category = category
        draft.provider = provider.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.amount = amount
        draft.currencyCode = currencyCode
        draft.frequency = frequency
        draft.renewalDate = hasRenewalDate ? renewalDate : nil
        draft.startDate = startDate
        draft.reminderDaysBefore = reminderDaysBefore
        draft.notes = notes
        draft.iconSymbol = iconSymbol
        draft.colorHex = colorHex
        draft.monogram = monogram

        do {
            switch mode {
            case .create:
                _ = try deps.subscriptions.create(from: draft)
            case .edit(let subscription):
                try deps.subscriptions.update(subscription, with: draft)
            }
            return true
        } catch RepositoryError.freeTierLimitReached {
            showPaywall = true
            return false
        } catch {
            errorMessage = String(
                localized: "subscriptions.form.error",
                defaultValue: "No se pudo guardar la suscripción."
            )
            return false
        }
    }

    // MARK: - Privado

    /// Rellena los campos a partir de una suscripción existente (modo edición).
    private func populate(from subscription: Subscription) {
        name = subscription.name
        category = subscription.category
        provider = subscription.provider
        amountText = "\(subscription.amount)"
        currencyCode = subscription.currencyCode
        frequency = subscription.frequency
        if let renewal = subscription.renewalDate {
            hasRenewalDate = true
            renewalDate = renewal
        }
        startDate = subscription.startDate
        reminderDaysBefore = subscription.reminderDaysBefore
        iconSymbol = subscription.iconSymbol
        colorHex = subscription.colorHex
        monogram = subscription.monogram
        notes = subscription.notes
    }
}
