//
//  DayEventsSheet.swift
//  Subscription Guardian
//
//  Hoja con los eventos financieros de un día concreto.
//

import SwiftUI

struct DayEventsSheet: View {
    let day: Date
    let events: [CalendarEvent]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if events.isEmpty {
                    Text("calendar.day.empty", comment: "Sin eventos este día")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: AppSpacing.s) {
                            ForEach(events) { event in
                                eventRow(event)
                            }
                        }
                        .padding(AppSpacing.m)
                    }
                }
            }
            .appBackground()
            .navigationTitle(Text(day, format: .dateTime.weekday(.wide).day().month(.wide)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.close", defaultValue: "Cerrar")) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func eventRow(_ event: CalendarEvent) -> some View {
        HStack(spacing: AppSpacing.m) {
            RoundedRectangle(cornerRadius: 2)
                .fill(event.color())
                .frame(width: 4, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline.weight(.medium))
                Text(kindLabel(event.kind))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let amount = event.amount {
                Text(amount, format: .currency(code: event.currencyCode))
                    .font(.subheadline.bold())
            }
        }
        .glassCard(cornerRadius: AppRadius.control)
    }

    private func kindLabel(_ kind: CalendarEvent.Kind) -> String {
        switch kind {
        case .subscriptionRenewal:
            return String(localized: "calendar.kind.renewal", defaultValue: "Renovación de suscripción")
        case .installment:
            return String(localized: "calendar.kind.installment", defaultValue: "Cuota de financiación")
        case .financingEnd:
            return String(localized: "calendar.kind.financingEnd", defaultValue: "Fin de financiación")
        }
    }
}
