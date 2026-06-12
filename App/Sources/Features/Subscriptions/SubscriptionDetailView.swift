//
//  SubscriptionDetailView.swift
//  Subscription Guardian
//
//  Detalle de una suscripción: cabecera, KPIs, datos y acciones
//  (marcar uso, pausar/reactivar, editar y eliminar).
//

import SwiftUI
import SubscriptionGuardianCore

/// Pantalla de detalle de una suscripción.
struct SubscriptionDetailView: View {
    @Environment(\.dependencies) private var deps
    @Environment(\.dismiss) private var dismiss

    let subscription: Subscription

    @State private var showEditForm = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.m) {
                hero
                kpiRow
                detailsSection
                actionsSection
            }
            .padding(AppSpacing.m)
        }
        .appBackground()
        .navigationTitle(subscription.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: "common.edit", defaultValue: "Editar")) {
                    showEditForm = true
                }
            }
        }
        .sheet(isPresented: $showEditForm) {
            SubscriptionFormView(mode: .edit(subscription))
        }
        .confirmationDialog(
            String(
                localized: "subscriptions.delete.title",
                defaultValue: "¿Eliminar esta suscripción?"
            ),
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                String(localized: "common.delete", defaultValue: "Eliminar"),
                role: .destructive
            ) {
                deleteSubscription()
            }
            Button(
                String(localized: "common.cancel", defaultValue: "Cancelar"),
                role: .cancel
            ) {}
        }
    }

    // MARK: - Secciones

    /// Cabecera con el icono grande, el nombre y la categoría.
    private var hero: some View {
        VStack(spacing: AppSpacing.m) {
            BrandIconView(
                symbol: subscription.iconSymbol,
                monogram: subscription.monogram,
                colorHex: subscription.colorHex,
                size: 76
            )

            Text(subscription.name)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            HStack(spacing: AppSpacing.s) {
                PillBadge(
                    text: subscription.category.localizedName,
                    tint: subscription.category.tintColor
                )
                PillBadge(text: statusName, tint: statusTint)
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    /// Indicadores clave: precio, equivalente mensual y próxima renovación.
    private var kpiRow: some View {
        HStack(alignment: .top, spacing: AppSpacing.m) {
            KPICard(
                title: String(
                    localized: "subscriptions.detail.price",
                    defaultValue: "Precio"
                ),
                value: subscription.amount
                    .formatted(.currency(code: subscription.currencyCode)),
                icon: "creditcard.fill",
                tint: .appCyan
            )

            KPICard(
                title: String(
                    localized: "subscriptions.detail.monthly",
                    defaultValue: "Al mes"
                ),
                value: monthlyEquivalent
                    .formatted(.currency(code: subscription.currencyCode)),
                icon: "calendar.badge.clock",
                tint: .appCyan
            )

            KPICard(
                title: String(
                    localized: "subscriptions.detail.renewal",
                    defaultValue: "Renovación"
                ),
                value: nextRenewalText,
                icon: "arrow.triangle.2.circlepath",
                tint: .orange
            )
        }
    }

    /// Datos adicionales: proveedor, fecha de alta, recordatorio y notas.
    private var detailsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.m) {
                detailRow(
                    title: String(
                        localized: "subscriptions.detail.provider",
                        defaultValue: "Proveedor"
                    ),
                    value: subscription.provider.isEmpty ? "—" : subscription.provider
                )

                detailRow(
                    title: String(
                        localized: "subscriptions.detail.startdate",
                        defaultValue: "Fecha de alta"
                    ),
                    value: subscription.startDate?
                        .formatted(date: .abbreviated, time: .omitted) ?? "—"
                )

                detailRow(
                    title: String(
                        localized: "subscriptions.detail.reminder",
                        defaultValue: "Recordatorio"
                    ),
                    value: String(
                        localized: "subscriptions.detail.reminder.days",
                        defaultValue: "\(subscription.reminderDaysBefore) días antes"
                    )
                )

                if !subscription.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(
                            localized: "subscriptions.detail.notes",
                            defaultValue: "Notas"
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        Text(subscription.notes)
                            .font(.subheadline)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Acciones disponibles sobre la suscripción.
    private var actionsSection: some View {
        VStack(spacing: AppSpacing.m) {
            Button {
                markUsed()
            } label: {
                Label(
                    String(
                        localized: "subscriptions.action.used",
                        defaultValue: "Lo estoy usando"
                    ),
                    systemImage: "hand.thumbsup.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)

            if let lastUsed = subscription.lastUsedAt {
                Text(String(
                    localized: "subscriptions.detail.lastused",
                    defaultValue: "Último uso: \(lastUsed.formatted(date: .abbreviated, time: .omitted))"
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: AppSpacing.m) {
                Button {
                    togglePaused()
                } label: {
                    Label(pauseActionTitle, systemImage: pauseActionSymbol)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 24)
                }
                .glassCard(cornerRadius: AppRadius.control, padding: 12)

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label(
                        String(localized: "common.delete", defaultValue: "Eliminar"),
                        systemImage: "trash"
                    )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, minHeight: 24)
                }
                .glassCard(cornerRadius: AppRadius.control, padding: 12)
            }
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }

    // MARK: - Valores derivados

    private var monthlyEquivalent: Decimal {
        SpendingCalculator.monthlyEquivalent(
            amount: subscription.amount,
            frequency: subscription.frequency
        )
    }

    private var nextRenewalText: String {
        guard let next = subscription.nextRenewal(after: .now) else { return "—" }
        return next.formatted(date: .abbreviated, time: .omitted)
    }

    private var statusName: String {
        switch subscription.status {
        case .active:
            return String(localized: "subscriptions.status.active", defaultValue: "Activa")
        case .paused:
            return String(localized: "subscriptions.status.paused", defaultValue: "Pausada")
        case .cancelled:
            return String(localized: "subscriptions.status.cancelled", defaultValue: "Cancelada")
        }
    }

    private var statusTint: Color {
        switch subscription.status {
        case .active: return .green
        case .paused: return .orange
        case .cancelled: return .gray
        }
    }

    private var pauseActionTitle: String {
        if subscription.status == .active {
            return String(localized: "subscriptions.action.pause", defaultValue: "Pausar")
        }
        return String(localized: "subscriptions.action.resume", defaultValue: "Reactivar")
    }

    private var pauseActionSymbol: String {
        subscription.status == .active ? "pause.fill" : "play.fill"
    }

    // MARK: - Acciones

    private func markUsed() {
        guard let deps else { return }
        try? deps.subscriptions.markUsed(subscription)
    }

    private func togglePaused() {
        guard let deps else { return }
        let newStatus: SubscriptionStatus = subscription.status == .active ? .paused : .active
        try? deps.subscriptions.setStatus(subscription, status: newStatus)
    }

    private func deleteSubscription() {
        guard let deps else { return }
        try? deps.subscriptions.delete(subscription)
        dismiss()
    }
}
