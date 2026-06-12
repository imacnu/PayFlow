//
//  SubscriptionGuardianShortcuts.swift
//  Subscription Guardian
//
//  Frases de invocación de Siri / Apple Intelligence para los intents.
//

import AppIntents

struct SubscriptionGuardianShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: MonthlySpendIntent(),
            phrases: [
                "Cuánto gasto al mes en \(.applicationName)",
                "Mi gasto mensual en \(.applicationName)",
                "How much do I spend monthly in \(.applicationName)"
            ],
            shortTitle: "Gasto mensual",
            systemImageName: "eurosign.circle.fill"
        )
        AppShortcut(
            intent: UpcomingRenewalsIntent(),
            phrases: [
                "Qué se renueva esta semana en \(.applicationName)",
                "Renovaciones de esta semana en \(.applicationName)",
                "What renews this week in \(.applicationName)"
            ],
            shortTitle: "Renovaciones",
            systemImageName: "bell.badge.fill"
        )
        AppShortcut(
            intent: FinancingEndDateIntent(),
            phrases: [
                "Cuándo termina mi financiación en \(.applicationName)",
                "Cuotas pendientes en \(.applicationName)",
                "When does my financing end in \(.applicationName)"
            ],
            shortTitle: "Fin de financiación",
            systemImageName: "creditcard.fill"
        )
    }
}
