import WidgetKit
import SwiftUI
import SubscriptionGuardianCore

/// Widget pequeño que muestra el próximo cargo (suscripción o cuota).
struct NextPaymentWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NextPaymentWidget", provider: SnapshotProvider()) { entry in
            NextPaymentView(snapshot: entry.snapshot)
        }
        .configurationDisplayName(
            String(localized: "widget.nextPayment.title", defaultValue: "Próximo pago")
        )
        .description(
            String(
                localized: "widget.nextPayment.description",
                defaultValue: "Tu próximo cargo de un vistazo."
            )
        )
        .supportedFamilies([.systemSmall])
    }
}

/// Vista del widget de próximo pago.
struct NextPaymentView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        Group {
            if let payment = snapshot.nextPayments.first {
                VStack(alignment: .leading, spacing: 6) {
                    // Franja de acento con degradado azul-cian.
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [WidgetConfig.electricBlue, WidgetConfig.appCyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 36, height: 5)

                    Text(payment.name)
                        .font(.headline)
                        .lineLimit(1)

                    Text(payment.amount, format: .currency(code: payment.currencyCode))
                        .font(.title2.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .foregroundStyle(WidgetConfig.electricBlue)

                    Spacer(minLength: 0)

                    // Fecha relativa del cargo (p. ej. "en 2 días").
                    Text(payment.date, style: .relative)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                // Estado vacío: no hay cargos próximos.
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                        .foregroundStyle(WidgetConfig.appCyan)
                    Text(
                        String(
                            localized: "widget.nextPayment.empty",
                            defaultValue: "Sin pagos próximos"
                        )
                    )
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .modifier(WidgetBackground())
    }
}
