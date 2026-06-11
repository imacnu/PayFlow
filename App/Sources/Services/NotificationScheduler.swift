import Foundation
import UserNotifications
import SubscriptionGuardianCore

/// Programador de notificaciones locales de renovaciones y cuotas.
/// Envuelve `UNUserNotificationCenter` y traduce los `PlannedReminder`
/// del paquete Core en solicitudes de notificación.
@MainActor
final class NotificationScheduler {
    private var center: UNUserNotificationCenter {
        UNUserNotificationCenter.current()
    }

    /// Solicita permiso de notificaciones solo si aún no se ha decidido.
    func requestAuthorizationIfNeeded() async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        do {
            _ = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            // El usuario podrá conceder el permiso más adelante desde Ajustes.
        }
    }

    /// Reprograma todas las notificaciones de la app: elimina las pendientes
    /// propias (prefijos "sub-" y "fin-") y añade las del nuevo plan.
    func reschedule(
        subscriptions: [SubscriptionSummary],
        reminderDays: [UUID: Int],
        financings: [FinancingSummary]
    ) async {
        let plan = ReminderPlanner.plan(
            subscriptions: subscriptions,
            reminderDays: reminderDays,
            financings: financings
        )

        // Eliminamos únicamente nuestras solicitudes pendientes.
        let pending = await center.pendingNotificationRequests()
        let staleIdentifiers = pending
            .map(\.identifier)
            .filter { $0.hasPrefix("sub-") || $0.hasPrefix("fin-") }
        if !staleIdentifiers.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: staleIdentifiers)
        }

        let calendar = Calendar.current
        for reminder in plan {
            let request = makeRequest(for: reminder, calendar: calendar)
            try? await center.add(request)
        }
    }

    // MARK: - Privado

    /// Construye la solicitud de notificación para un recordatorio planificado.
    private func makeRequest(
        for reminder: PlannedReminder,
        calendar: Calendar
    ) -> UNNotificationRequest {
        let amountText = reminder.amount.formatted(.currency(code: reminder.currencyCode))
        let dateText = reminder.eventDate.formatted(.dateTime.day().month())

        let content = UNMutableNotificationContent()
        switch reminder.kind {
        case .subscriptionRenewal:
            content.title = String(
                localized: "notifications.renewal.title",
                defaultValue: "Renovación próxima"
            )
            content.body = String(
                localized: "notifications.renewal.body",
                defaultValue: "\(reminder.entityName) se renueva el \(dateText) por \(amountText)"
            )
        case .financingInstallment:
            content.title = String(
                localized: "notifications.installment.title",
                defaultValue: "Cuota próxima"
            )
            content.body = String(
                localized: "notifications.installment.body",
                defaultValue: "\(reminder.entityName): cuota de \(amountText) el \(dateText)"
            )
        }
        content.sound = .default

        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminder.fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(
            identifier: reminder.identifier,
            content: content,
            trigger: trigger
        )
    }
}
