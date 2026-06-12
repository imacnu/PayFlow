//
//  NotificationCenterView.swift
//  Subscription Guardian
//
//  Centro de notificaciones in-app: renovaciones, cuotas, subidas de
//  precio y suscripciones sin uso.
//

import SwiftUI
import SubscriptionGuardianCore

struct NotificationCenterView: View {
    @Environment(\.dependencies) private var deps
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = NotificationsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.notifications.isEmpty {
                    EmptyStateView(
                        icon: "bell.slash.fill",
                        title: String(localized: "notifications.empty.title", defaultValue: "Sin notificaciones"),
                        message: String(
                            localized: "notifications.empty.message",
                            defaultValue: "Aquí verás renovaciones próximas, cuotas y avisos de ahorro."
                        )
                    )
                } else {
                    List {
                        ForEach(viewModel.notifications, id: \.id) { notification in
                            notificationRow(notification)
                                .listRowBackground(Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.markRead(notification)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        viewModel.delete(notification)
                                    } label: {
                                        Label(
                                            String(localized: "common.delete", defaultValue: "Eliminar"),
                                            systemImage: "trash"
                                        )
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .appBackground()
            .navigationTitle(Text("notifications.title", comment: "Notificaciones"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.close", defaultValue: "Cerrar")) {
                        dismiss()
                    }
                }
                if viewModel.unreadCount > 0 {
                    ToolbarItem(placement: .primaryAction) {
                        Button(String(localized: "notifications.markAll", defaultValue: "Marcar todo")) {
                            viewModel.markAllRead()
                        }
                    }
                }
            }
        }
        .task {
            viewModel.configure(deps: deps)
            viewModel.load()
        }
    }

    // MARK: - Fila

    private func notificationRow(_ notification: AppNotification) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.m) {
            Image(systemName: iconName(for: notification.type))
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(tint(for: notification.type)))

            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(.subheadline.weight(notification.isRead ? .regular : .semibold))
                Text(notification.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(notification.date, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if !notification.isRead {
                Circle()
                    .fill(Color.electricBlue)
                    .frame(width: 9, height: 9)
                    .padding(.top, 6)
            }
        }
        .padding(.vertical, 4)
    }

    private func iconName(for type: AppNotificationType) -> String {
        switch type {
        case .renewalUpcoming: return "bell.badge.fill"
        case .installmentUpcoming: return "creditcard.fill"
        case .priceIncrease: return "arrow.up.circle.fill"
        case .unusedSubscription: return "moon.zzz.fill"
        }
    }

    private func tint(for type: AppNotificationType) -> Color {
        switch type {
        case .renewalUpcoming: return .electricBlue
        case .installmentUpcoming: return .appCyan
        case .priceIncrease: return .red
        case .unusedSubscription: return .purple
        }
    }
}

#Preview {
    NotificationCenterView()
        .environment(\.dependencies, AppDependencies.preview())
}
