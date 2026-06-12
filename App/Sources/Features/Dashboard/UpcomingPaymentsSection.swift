//
//  UpcomingPaymentsSection.swift
//  Subscription Guardian
//
//  Próximos pagos combinados (renovaciones y cuotas) con separación
//  semántica clara: fecha, servicio, tipo e importe escaneables de un
//  vistazo. El vacío transmite calma, no ausencia.
//

import SwiftUI

struct UpcomingPaymentsSection: View {
    let items: [DashboardViewModel.UpcomingItem]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            Text("dashboard.upcoming.title", comment: "Próximos pagos")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if items.isEmpty {
                calmEmptyState
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(items) { item in
                        UpcomingPaymentRow(item: item)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    /// Vacío en calma: orden y tranquilidad, no un hueco muerto.
    private var calmEmptyState: some View {
        HStack(spacing: AppSpacing.m) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title3)
                .foregroundStyle(Color.appLime)
                .glow(.appLime, radius: 8, opacity: 0.4)

            Text("dashboard.upcoming.empty", comment: "Sin pagos a la vista. Todo en calma.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
        .padding(.vertical, AppSpacing.s)
    }
}

/// Fila de un próximo pago: cápsula de fecha, nombre + tipo e importe.
private struct UpcomingPaymentRow: View {
    let item: DashboardViewModel.UpcomingItem

    /// Un pago es inminente si vence en los próximos 3 días.
    private var isImminent: Bool {
        item.date.timeIntervalSinceNow < 3 * 24 * 3600
    }

    var body: some View {
        HStack(spacing: AppSpacing.m) {
            // Cápsula de fecha: día protagonista, mes de apoyo.
            VStack(spacing: 0) {
                Text(item.date, format: .dateTime.day())
                    .font(.system(.headline, design: .rounded))
                Text(item.date, format: .dateTime.month(.abbreviated))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                    .fill(
                        isImminent
                            ? Color.appAmber.opacity(0.16)
                            : Color.electricBlue.opacity(0.12)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                    .strokeBorder(
                        (isImminent ? Color.appAmber : Color.electricBlue).opacity(0.25),
                        lineWidth: 1
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
                .foregroundStyle(.tertiary)
            }

            Spacer()

            Text(item.amount, format: .currency(code: item.currencyCode))
                .font(.system(.subheadline, design: .rounded).bold())
                .foregroundStyle(isImminent ? Color.appAmber : Color.primary)
        }
    }
}
