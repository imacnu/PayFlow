//
//  FinancingEndDateIntent.swift
//  Subscription Guardian
//
//  Intent: "¿Cuándo termina mi financiación de <comercio>?" — informa de
//  la fecha de finalización y las cuotas pendientes.
//

import Foundation
import AppIntents
import SwiftData
import SubscriptionGuardianCore

struct FinancingEndDateIntent: AppIntent {
    static let title: LocalizedStringResource = "¿Cuándo termina mi financiación?"
    static let description = IntentDescription(
        "Indica cuándo termina una financiación y cuántas cuotas quedan."
    )

    @Parameter(title: "Comercio")
    var merchant: String?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let container = SharedModelContainer.shared.container else {
            throw IntentError.notReady
        }
        let context = container.mainContext

        let financings = ((try? context.fetch(FetchDescriptor<Financing>())) ?? [])
            .filter { $0.status == .active }

        guard !financings.isEmpty else {
            let message = String(
                localized: "intents.financingEnd.none",
                defaultValue: "No tienes financiaciones activas."
            )
            return .result(dialog: IntentDialog(stringLiteral: message))
        }

        // Selección: por nombre de comercio o, si solo hay una, esa.
        let match: Financing?
        if let merchant, !merchant.isEmpty {
            match = financings.first {
                $0.merchant.localizedCaseInsensitiveContains(merchant)
            }
        } else if financings.count == 1 {
            match = financings.first
        } else {
            match = nil
        }

        guard let financing = match else {
            let merchants = financings.map { $0.merchant }.joined(separator: ", ")
            let message = String(
                localized: "intents.financingEnd.ambiguous",
                defaultValue: "Tienes varias financiaciones activas: \(merchants). Especifica el comercio."
            )
            return .result(dialog: IntentDialog(stringLiteral: message))
        }

        let message: String
        if let endDate = financing.endDate {
            let dateText = endDate.formatted(.dateTime.day().month(.wide).year())
            message = String(
                localized: "intents.financingEnd.result",
                defaultValue: "Tu financiación de \(financing.merchant) termina el \(dateText) (quedan \(financing.pendingInstallments) cuotas)."
            )
        } else {
            message = String(
                localized: "intents.financingEnd.noDate",
                defaultValue: "Tu financiación de \(financing.merchant) tiene \(financing.pendingInstallments) cuotas pendientes, pero no tiene fecha registrada."
            )
        }
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}
