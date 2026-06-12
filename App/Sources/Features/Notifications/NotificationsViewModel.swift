//
//  NotificationsViewModel.swift
//  Subscription Guardian
//
//  ViewModel del centro de notificaciones in-app.
//

import Foundation
import Observation
import SubscriptionGuardianCore

@MainActor
@Observable
final class NotificationsViewModel {
    var notifications: [AppNotification] = []

    private var dependencies: AppDependencies?

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    func configure(deps: AppDependencies?) {
        dependencies = deps
    }

    func load() {
        guard let deps = dependencies else { return }
        notifications = (try? deps.notifications.all()) ?? []
    }

    func markRead(_ notification: AppNotification) {
        guard let deps = dependencies else { return }
        try? deps.notifications.markRead(notification)
        load()
    }

    func markAllRead() {
        guard let deps = dependencies else { return }
        try? deps.notifications.markAllRead()
        load()
    }

    func delete(_ notification: AppNotification) {
        guard let deps = dependencies else { return }
        try? deps.notifications.delete(notification)
        load()
    }
}
