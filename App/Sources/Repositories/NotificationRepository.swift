import Foundation
import SwiftData
import SubscriptionGuardianCore

/// Contrato del repositorio del buzón de notificaciones internas.
@MainActor
protocol NotificationRepositoryProtocol: AnyObject {
    /// Todas las notificaciones, de más reciente a más antigua.
    func all() throws -> [AppNotification]
    /// Número de notificaciones sin leer.
    func unreadCount() throws -> Int
    /// Marca una notificación como leída.
    func markRead(_ notification: AppNotification) throws
    /// Marca todas las notificaciones como leídas.
    func markAllRead() throws
    /// Inserta una notificación, evitando duplicados sin leer
    /// del mismo tipo y entidad relacionada.
    func insert(type: AppNotificationType, title: String, body: String, relatedEntityID: UUID?) throws
    /// Elimina una notificación.
    func delete(_ notification: AppNotification) throws
}

/// Repositorio del buzón de notificaciones respaldado por SwiftData.
@MainActor
final class SwiftDataNotificationRepository: NotificationRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func all() throws -> [AppNotification] {
        let descriptor = FetchDescriptor<AppNotification>(
            sortBy: [SortDescriptor(\AppNotification.date, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func unreadCount() throws -> Int {
        try all().filter { !$0.isRead }.count
    }

    func markRead(_ notification: AppNotification) throws {
        notification.isRead = true
        try context.save()
    }

    func markAllRead() throws {
        for notification in try all() where !notification.isRead {
            notification.isRead = true
        }
        try context.save()
    }

    func insert(
        type: AppNotificationType,
        title: String,
        body: String,
        relatedEntityID: UUID?
    ) throws {
        // Deduplicación: no insertamos si ya existe una notificación sin leer
        // del mismo tipo y para la misma entidad relacionada.
        let existing = try all()
        let isDuplicate = existing.contains {
            !$0.isRead
                && $0.typeRaw == type.rawValue
                && $0.relatedEntityID == relatedEntityID
        }
        guard !isDuplicate else { return }

        let notification = AppNotification(
            type: type,
            title: title,
            body: body,
            date: Date(),
            isRead: false,
            relatedEntityID: relatedEntityID
        )
        context.insert(notification)
        try context.save()
    }

    func delete(_ notification: AppNotification) throws {
        context.delete(notification)
        try context.save()
    }
}
