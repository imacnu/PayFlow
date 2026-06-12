//
//  CalendarViewModel.swift
//  Subscription Guardian
//
//  ViewModel del calendario financiero: genera los eventos del mes visible
//  a partir de suscripciones y financiaciones.
//

import Foundation
import Observation
import SubscriptionGuardianCore

@MainActor
@Observable
final class CalendarViewModel {
    /// Primer día del mes mostrado.
    var displayedMonth: Date
    /// Día seleccionado por el usuario (para la hoja de eventos).
    var selectedDay: Date?
    /// Eventos del mes agrupados por día (clave = startOfDay).
    private(set) var eventsByDay: [Date: [CalendarEvent]] = [:]

    private var dependencies: AppDependencies?
    private let calendar = Calendar.current

    init() {
        let now = Date()
        displayedMonth = Calendar.current.dateInterval(of: .month, for: now)?.start ?? now
    }

    /// Eventos del mes ordenados por fecha (para la lista bajo la cuadrícula).
    var monthEvents: [CalendarEvent] {
        eventsByDay.values.flatMap { $0 }.sorted { $0.date < $1.date }
    }

    /// Eventos del día seleccionado.
    var selectedDayEvents: [CalendarEvent] {
        guard let selectedDay else { return [] }
        return eventsByDay[calendar.startOfDay(for: selectedDay)] ?? []
    }

    func configure(deps: AppDependencies?) {
        dependencies = deps
    }

    func load() {
        guard let deps = dependencies,
              let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else {
            return
        }

        var events: [CalendarEvent] = []

        // Renovaciones de suscripciones activas dentro del mes.
        let subscriptions = (try? deps.subscriptions.summaries()) ?? []
        for subscription in subscriptions where subscription.status == .active {
            let anchor = subscription.nextRenewal ?? subscription.startDate ?? subscription.createdAt
            let renewals = RecurrenceCalculator.renewals(
                anchor: anchor,
                frequency: subscription.frequency,
                in: monthInterval,
                calendar: calendar
            )
            for renewal in renewals {
                events.append(
                    CalendarEvent(
                        id: "sub-\(subscription.id.uuidString)-\(renewal.timeIntervalSince1970)",
                        date: renewal,
                        title: subscription.name,
                        amount: subscription.amount,
                        currencyCode: subscription.currencyCode,
                        kind: .subscriptionRenewal
                    )
                )
            }
        }

        // Cuotas pendientes y fechas de finalización de financiaciones activas.
        let financings = (try? deps.financings.summaries()) ?? []
        for financing in financings where financing.status == .active {
            guard let firstDate = financing.firstInstallmentDate else { continue }

            for installment in financing.paidInstallments..<financing.totalInstallments {
                guard let dueDate = calendar.date(byAdding: .month, value: installment, to: firstDate),
                      monthInterval.contains(dueDate) else { continue }
                events.append(
                    CalendarEvent(
                        id: "fin-\(financing.id.uuidString)-\(installment)",
                        date: dueDate,
                        title: financing.merchant,
                        amount: financing.monthlyAmount,
                        currencyCode: "EUR",
                        kind: .installment
                    )
                )
            }

            if let endDate = FinancingCalculator.endDate(financing, calendar: calendar),
               monthInterval.contains(endDate) {
                events.append(
                    CalendarEvent(
                        id: "fin-end-\(financing.id.uuidString)",
                        date: endDate,
                        title: financing.merchant,
                        amount: nil,
                        currencyCode: "EUR",
                        kind: .financingEnd
                    )
                )
            }
        }

        eventsByDay = Dictionary(grouping: events) { calendar.startOfDay(for: $0.date) }
    }

    func previousMonth() {
        guard let previous = calendar.date(byAdding: .month, value: -1, to: displayedMonth) else { return }
        displayedMonth = previous
        load()
    }

    func nextMonth() {
        guard let next = calendar.date(byAdding: .month, value: 1, to: displayedMonth) else { return }
        displayedMonth = next
        load()
    }
}
