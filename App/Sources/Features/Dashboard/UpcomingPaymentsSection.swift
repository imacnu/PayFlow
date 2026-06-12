//
//  UpcomingPaymentsSection.swift
//  Subscription Guardian
//
//  Sección del panel con los próximos pagos combinados (renovaciones de
//  suscripciones y cuotas de financiaciones).
//

import SwiftUI

struct UpcomingPaymentsSection: View {
    let items: [DashboardViewModel.UpcomingItem]

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.m) {
                Text("dashboard.upcoming.title", comment: "Próximos pagos")
                    .font(.headline)

                if items.isEmpty {
                    Text("dashboard.upcoming.empty", comment: "No hay pagos próximos")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: AppSpacing.s) {
                        ForEach(items) { item in
                            UpcomingPaymentRow(item: item)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// Fila de un próximo pago: fecha en círculo, nombre e importe.
private struct UpcomingPaymentRow: View {
    let item: DashboardViewModel.UpcomingItem

    /// Un pago es inminente si vence en los próximos 3 días.
    private var isImminent: Bool {
        item.date.timeIntervalSinceNow < 3 * 24 * 3600
    }

    var body: some View {
        HStack(spacing: AppSpacing.m) {
            VStack(spacing: 0) {
                Text(item.date, format: .dateTime.day())
                    .font(.headline)
                Text(item.date, format: .dateTime.month(.abbreviated))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 44, height: 44)
            .background(
                Circle().fill(
                    isImminent ? Color.orange.opacity(0.18) : Color.electricBlue.opacity(0.12)
                )
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.weight(.medium))
                Text(
                    item.isFinancing
                        ? String(localized: "dashboard.upcoming.installment", defaultValue: "Cuota")
                        : String(localized: "dashboard.upcoming.renewal", defaultValue: "Renovación")
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(item.amount, format: .currency(code: item.currencyCode))
                .font(.subheadline.bold())
                .foregroundStyle(isImminent ? .orange : .primary)
        }
    }
}
