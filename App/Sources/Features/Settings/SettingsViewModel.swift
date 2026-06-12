//
//  SettingsViewModel.swift
//  Subscription Guardian
//
//  ViewModel de ajustes: cuenta, estado premium, exportación CSV y datos.
//

import Foundation
import Observation
import SubscriptionGuardianCore

@MainActor
@Observable
final class SettingsViewModel {
    /// URL del CSV generado, lista para compartir.
    var exportURL: URL?
    /// Error mostrable.
    var errorMessage: String?

    private(set) var subscriptionCount = 0
    private(set) var financingCount = 0

    private var dependencies: AppDependencies?

    var isPremium: Bool {
        dependencies?.entitlements.isPremium ?? false
    }

    var session: SessionStore? {
        dependencies?.session
    }

    /// Texto de uso del plan gratuito, p. ej. "12/15 suscripciones".
    var usageDescription: String {
        String(
            localized: "settings.usage",
            defaultValue: "\(subscriptionCount)/\(AppConfig.freeSubscriptionLimit) suscripciones · \(financingCount)/\(AppConfig.freeFinancingLimit) financiaciones"
        )
    }

    func configure(deps: AppDependencies?) {
        dependencies = deps
    }

    func load() {
        guard let deps = dependencies else { return }
        subscriptionCount = (try? deps.subscriptions.all().count) ?? 0
        financingCount = (try? deps.financings.all().count) ?? 0
    }

    /// Genera el CSV en un archivo temporal para compartirlo.
    func prepareExport() {
        guard let deps = dependencies else { return }
        do {
            let content = CSVExportService.export(
                subscriptions: try deps.subscriptions.summaries(),
                financings: try deps.financings.summaries()
            )
            exportURL = try CSVExportService.writeTemporaryFile(content: content)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        dependencies?.session.signOut()
    }

    func requestNotificationPermission() {
        guard let deps = dependencies else { return }
        Task { await deps.scheduler.requestAuthorizationIfNeeded() }
    }
}
