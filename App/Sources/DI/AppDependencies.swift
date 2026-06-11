import Foundation
import Observation
import SwiftData
import SubscriptionGuardianCore

/// Contenedor de dependencias de la app. Se construye una vez al arrancar
/// y se inyecta en la jerarquía de vistas a través del entorno.
@MainActor
@Observable
final class AppDependencies {
    let container: ModelContainer
    let subscriptions: SubscriptionRepositoryProtocol
    let financings: FinancingRepositoryProtocol
    let notifications: NotificationRepositoryProtocol
    let session: SessionStore
    let scheduler: NotificationScheduler
    let purchases: PurchaseService
    let entitlements: EntitlementStore
    let snapshotWriter: WidgetSnapshotWriter
    let googleSignIn: GoogleSignInService

    init(container: ModelContainer) {
        self.container = container
        let context = container.mainContext

        let entitlements = EntitlementStore()
        let subscriptionRepository = SwiftDataSubscriptionRepository(
            context: context,
            entitlements: entitlements
        )
        let financingRepository = SwiftDataFinancingRepository(
            context: context,
            entitlements: entitlements
        )

        self.entitlements = entitlements
        self.subscriptions = subscriptionRepository
        self.financings = financingRepository
        self.notifications = SwiftDataNotificationRepository(context: context)
        self.session = SessionStore()
        self.scheduler = NotificationScheduler()
        self.purchases = PurchaseService(entitlements: entitlements)
        self.snapshotWriter = WidgetSnapshotWriter()
        self.googleSignIn = GoogleSignInService()

        // Con `self` ya inicializado por completo, conectamos los callbacks
        // de cambio de los repositorios con la propagación de datos.
        subscriptionRepository.onChange = { [weak self] in self?.dataDidChange() }
        financingRepository.onChange = { [weak self] in self?.dataDidChange() }
    }

    /// Dependencias para previews: contenedor en memoria con datos de ejemplo.
    static func preview() -> AppDependencies {
        let dependencies = AppDependencies(container: ModelContainerFactory.makeInMemory())
        dependencies.seedSampleData()
        return dependencies
    }

    /// Propagación de cambios de datos: escribe el snapshot del widget y
    /// reprograma las notificaciones locales.
    func dataDidChange() {
        let subscriptionSummaries = (try? subscriptions.summaries()) ?? []
        let financingSummaries = (try? financings.summaries()) ?? []

        snapshotWriter.write(
            subscriptions: subscriptionSummaries,
            financings: financingSummaries,
            isPremium: entitlements.isPremium
        )

        let reminderDays = Dictionary(
            ((try? subscriptions.all()) ?? []).map { ($0.id, $0.reminderDaysBefore) },
            uniquingKeysWith: { first, _ in first }
        )
        Task {
            await scheduler.reschedule(
                subscriptions: subscriptionSummaries,
                reminderDays: reminderDays,
                financings: financingSummaries
            )
        }
    }

    // MARK: - Privado

    /// Siembra datos de ejemplo para previews (3 suscripciones y 1 financiación).
    private func seedSampleData() {
        let calendar = Calendar.current
        let now = Date()

        var netflix = SubscriptionDraft()
        netflix.name = "Netflix"
        netflix.category = .streaming
        netflix.amount = Decimal(string: "13.99") ?? 0
        netflix.renewalDate = calendar.date(byAdding: .day, value: 4, to: now)
        netflix.iconSymbol = "play.tv.fill"
        netflix.colorHex = "E50914"
        netflix.monogram = "N"

        var spotify = SubscriptionDraft()
        spotify.name = "Spotify"
        spotify.category = .music
        spotify.amount = Decimal(string: "10.99") ?? 0
        spotify.renewalDate = calendar.date(byAdding: .day, value: 9, to: now)
        spotify.iconSymbol = "music.note"
        spotify.colorHex = "1DB954"
        spotify.monogram = "S"

        var icloud = SubscriptionDraft()
        icloud.name = "iCloud+"
        icloud.category = .productivity
        icloud.amount = Decimal(string: "2.99") ?? 0
        icloud.renewalDate = calendar.date(byAdding: .day, value: 15, to: now)
        icloud.iconSymbol = "icloud.fill"
        icloud.colorHex = "1F6FEB"
        icloud.monogram = "iC"

        var financing = FinancingDraft()
        financing.merchant = "MediaMarkt"
        financing.provider = .klarna
        financing.totalAmount = Decimal(string: "498.00") ?? 0
        financing.monthlyAmount = Decimal(string: "41.50") ?? 0
        financing.totalInstallments = 12
        financing.firstInstallmentDate = calendar.date(byAdding: .month, value: -3, to: now)

        _ = try? subscriptions.create(from: netflix)
        _ = try? subscriptions.create(from: spotify)
        _ = try? subscriptions.create(from: icloud)
        if let created = try? financings.create(from: financing) {
            try? financings.markInstallmentPaid(created)
            try? financings.markInstallmentPaid(created)
            try? financings.markInstallmentPaid(created)
        }
    }
}
