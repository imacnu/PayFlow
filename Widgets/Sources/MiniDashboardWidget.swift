import WidgetKit
import SwiftUI
import SubscriptionGuardianCore

/// Widget grande: resumen mensual, próximos cargos y barras por categoría.
struct MiniDashboardWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MiniDashboardWidget", provider: SnapshotProvider()) { entry in
            MiniDashboardView(snapshot: entry.snapshot)
        }
        .configurationDisplayName(
            String(localized: "widget.miniDashboard.title", defaultValue: "Panel resumen")
        )
        .description(
            String(
                localized: "widget.miniDashboard.description",
                defaultValue: "Gasto mensual, próximos cargos y categorías."
            )
        )
        .supportedFamilies([.systemLarge])
    }
}

/// Vista del widget de panel resumen.
struct MiniDashboardView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            Divider()

            // Hasta 4 próximos cargos.
            if snapshot.nextPayments.isEmpty {
                Text(String(localized: "widget.nextPayment.empty", defaultValue: "Sin pagos próximos"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(snapshot.nextPayments.prefix(4))) { payment in
                        PaymentRow(payment: payment)
                    }
                }
            }

            Spacer(minLength: 0)

            // Barras de gasto por categoría (las 3 principales).
            if !snapshot.categoryBreakdown.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(snapshot.categoryBreakdown.prefix(3))) { slice in
                        CategoryBarRow(
                            slice: slice,
                            currencyCode: snapshot.currencyCode,
                            fraction: barFraction(for: slice)
                        )
                    }
                }
            }

            // Aviso para usuarios sin premium.
            if !snapshot.isPremium {
                Text(
                    String(
                        localized: "widget.miniDashboard.premiumNote",
                        defaultValue: "Hazte Premium para ver más"
                    )
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .modifier(WidgetBackground())
    }

    /// Cabecera: total mensual y contadores de elementos activos.
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "widget.monthlySpend.heading", defaultValue: "Gasto mensual"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(snapshot.monthlyTotal, format: .currency(code: snapshot.currencyCode))
                    .font(.title2.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(WidgetConfig.electricBlue)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(
                    String(
                        localized: "widget.pill.subscriptions",
                        defaultValue: "\(snapshot.activeSubscriptions) susc."
                    )
                )
                Text(
                    String(
                        localized: "widget.pill.financings",
                        defaultValue: "\(snapshot.activeFinancings) financ."
                    )
                )
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
        }
    }

    /// Proporción de la barra de una categoría respecto al total mensual,
    /// acotada entre 0 y 1.
    private func barFraction(for slice: SpendingCalculator.CategorySlice) -> Double {
        let total = doubleValue(snapshot.monthlyTotal)
        guard total > 0 else { return 0 }
        let fraction = doubleValue(slice.monthlyAmount) / total
        return min(max(fraction, 0), 1)
    }
}

/// Fila compacta de un próximo cargo: nombre, fecha e importe.
private struct PaymentRow: View {
    let payment: UpcomingPayment

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(payment.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(payment.date, format: .dateTime.day().month(.abbreviated))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            Text(payment.amount, format: .currency(code: payment.currencyCode))
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
        }
    }
}

/// Fila con barra de progreso proporcional al gasto de la categoría.
private struct CategoryBarRow: View {
    let slice: SpendingCalculator.CategorySlice
    let currencyCode: String
    let fraction: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                CategoryDot(category: slice.category)
                Text(categoryDisplayName(slice.category))
                    .font(.caption2)
                    .lineLimit(1)
                Spacer(minLength: 4)
                Text(slice.monthlyAmount, format: .currency(code: currencyCode))
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
            }
            ProgressView(value: fraction)
                .tint(categoryColor(slice.category))
        }
    }
}
