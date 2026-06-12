//
//  UpcomingRenewalsIntent.swift
//  Subscription Guardian
//
//  Intent: "¿Qué suscripciones vencen esta semana?" — lista las
//  renovaciones de los próximos 7 días.
//

import Foundation
import AppIntents
import SwiftData
import SubscriptionGuardianCore

struct UpcomingRenewalsIntent: AppIntent {
    static let title: LocalizedStringResource = "¿Qué se renueva esta semana?"
    static let description = IntentDescription(
        "Lista las suscripciones que se renuevan en los próximos 7 días."
    )

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let container = SharedModelContainer.shared.container else {
            throw IntentError.notReady
        }
        let context = container.mainContext
        let calendar = Calendar.current
        let now = Date()
        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: now) else {
            throw IntentError.notReady
        }

        let subscriptions = (try? context.fetch(FetchDescriptor<Subscription>())) ?? []

        // Renovaciones de suscripciones activas dentro de los próximos 7 días.
        var renewals: [(name: String, date: Date)] = []
        for subscription in subscriptions where subscription.status == .active {
            if let next = subscription.nextRenewal(after: now, calendar: calendar), next <= weekEnd {
                renewals.append((subscription.name, next))
            }
        }
        renewals.sort { $0.date < $1.date }

        let message: String
        if renewals.isEmpty {
            message = String(
                localized: "intents.upcomingRenewals.empty",
                defaultValue: "No tienes renovaciones esta semana."
            )
        } else {
            let listing = renewals
                .map { "\($0.name) (\($0.date.formatted(.dateTime.day().month(.abbreviated))))" }
                .joined(separator: ", ")
            message = String(
                localized: "intents.upcomingRenewals.result",
                defaultValue: "Esta semana se renuevan: \(listing)."
            )
        }
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}
