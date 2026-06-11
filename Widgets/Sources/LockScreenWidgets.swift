import WidgetKit
import SwiftUI
import SubscriptionGuardianCore

/// Widget de pantalla de bloqueo con el próximo cargo.
struct LockScreenNextPaymentWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "LockScreenNextPaymentWidget",
            provider: SnapshotProvider()
        ) { entry in
            LockScreenNextPaymentView(snapshot: entry.snapshot)
        }
        .configurationDisplayName(
            String(localized: "widget.lockScreen.title", defaultValue: "Próximo pago")
        )
        .description(
            String(
                localized: "widget.lockScreen.description",
                defaultValue: "Tu próximo cargo en la pantalla de bloqueo."
            )
        )
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

/// Vista del widget de pantalla de bloqueo; cambia según la familia.
struct LockScreenNextPaymentView: View {
    @Environment(\.widgetFamily) private var family

    let snapshot: WidgetSnapshot

    /// Primer cargo próximo, si existe.
    private var payment: UpcomingPayment? {
        snapshot.nextPayments.first
    }

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                circular
            case .accessoryRectangular:
                rectangular
            default:
                inline
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    /// Circular: solo el importe abreviado (sin decimales).
    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            if let payment {
                Text(
                    payment.amount,
                    format: .currency(code: payment.currencyCode)
                        .precision(.fractionLength(0))
                )
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            } else {
                Image(systemName: "checkmark")
                    .font(.headline)
            }
        }
    }

    /// Rectangular: nombre, fecha e importe en tres líneas compactas.
    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            if let payment {
                Text(payment.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(payment.date, format: .dateTime.day().month(.abbreviated))
                    .font(.caption2)
                    .lineLimit(1)
                Text(payment.amount, format: .currency(code: payment.currencyCode))
                    .font(.caption)
                    .lineLimit(1)
            } else {
                Text(
                    String(
                        localized: "widget.nextPayment.empty",
                        defaultValue: "Sin pagos próximos"
                    )
                )
                .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Inline: "Netflix · 12 jun".
    private var inline: some View {
        Group {
            if let payment {
                Text("\(payment.name) · \(payment.date, format: .dateTime.day().month(.abbreviated))")
            } else {
                Text(
                    String(
                        localized: "widget.nextPayment.empty",
                        defaultValue: "Sin pagos próximos"
                    )
                )
            }
        }
    }
}
