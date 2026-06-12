//
//  MonthlySpendIntent.swift
//  Subscription Guardian
//
//  Intent: "¿Cuánto gasto al mes?" — responde con el gasto mensual total
//  en suscripciones y financiaciones.
//

import Foundation
import AppIntents
import SwiftData
import SubscriptionGuardianCore

struct MonthlySpendIntent: AppIntent {
    static let title: LocalizedStringResource = "¿Cuánto gasto al mes?"
    static let description = IntentDescription(
        "Calcula tu gasto mensual total en suscripciones y financiaciones."
    )

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let container = SharedModelContainer.shared.container else {
            throw IntentError.notReady
        }
        let context = container.mainContext

        let subscriptions = (try? context.fetch(FetchDescriptor<Subscription>())) ?? []
        let financings = (try? context.fetch(FetchDescriptor<Financing>())) ?? []

        let total = SpendingCalculator.monthlyTotal(
            subscriptions: subscriptions.map { $0.summary },
            financings: financings.map { $0.summary }
        )
        let currencyCode = subscriptions.first?.currencyCode ?? "EUR"
        let formatted = total.formatted(.currency(code: currencyCode))

        let message = String(
            localized: "intents.monthlySpend.result",
            defaultValue: "Gastas \(formatted) al mes en suscripciones y financiaciones."
        )
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}
