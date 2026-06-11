import WidgetKit
import SwiftUI
import SubscriptionGuardianCore

/// Widget mediano con el gasto mensual total y el desglose por categorías.
struct MonthlySpendWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MonthlySpendWidget", provider: SnapshotProvider()) { entry in
            MonthlySpendView(snapshot: entry.snapshot)
        }
        .configurationDisplayName(
            String(localized: "widget.monthlySpend.title", defaultValue: "Gasto mensual")
        )
        .description(
            String(
                localized: "widget.monthlySpend.description",
                defaultValue: "Tu gasto mensual y las categorías principales."
            )
        )
        .supportedFamilies([.systemMedium])
    }
}

/// Vista del widget de gasto mensual.
struct MonthlySpendView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Columna izquierda: total y contadores.
            VStack(alignment: .leading, spacing: 6) {
                Text(String(localized: "widget.monthlySpend.heading", defaultValue: "Gasto mensual"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(snapshot.monthlyTotal, format: .currency(code: snapshot.currencyCode))
                    .font(.title.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(WidgetConfig.electricBlue)

                Spacer(minLength: 0)

                HStack(spacing: 6) {
                    CountPill(
                        text: String(
                            localized: "widget.pill.subscriptions",
                            defaultValue: "\(snapshot.activeSubscriptions) susc."
                        )
                    )
                    CountPill(
                        text: String(
                            localized: "widget.pill.financings",
                            defaultValue: "\(snapshot.activeFinancings) financ."
                        )
                    )
                }
            }

            // Columna derecha: las 3 categorías con más gasto.
            VStack(alignment: .leading, spacing: 8) {
                if snapshot.categoryBreakdown.isEmpty {
                    Text(
                        String(
                            localized: "widget.monthlySpend.noCategories",
                            defaultValue: "Sin categorías"
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(snapshot.categoryBreakdown.prefix(3))) { slice in
                        HStack(spacing: 6) {
                            CategoryDot(category: slice.category)
                            Text(categoryDisplayName(slice.category))
                                .font(.caption)
                                .lineLimit(1)
                            Spacer(minLength: 4)
                            Text(slice.monthlyAmount, format: .currency(code: snapshot.currencyCode))
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .modifier(WidgetBackground())
    }
}

/// Pastilla pequeña con un contador (suscripciones o financiaciones activas).
private struct CountPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(WidgetConfig.electricBlue.opacity(0.15)))
    }
}
