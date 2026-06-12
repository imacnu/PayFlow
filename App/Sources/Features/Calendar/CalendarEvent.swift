//
//  CalendarEvent.swift
//  Subscription Guardian
//
//  Evento del calendario financiero con su código de color:
//  azul = suscripciones, verde = fin de financiación,
//  naranja = pago próximo (≤ 3 días), rojo = vencido.
//

import SwiftUI

struct CalendarEvent: Identifiable, Hashable {
    enum Kind: Hashable {
        case subscriptionRenewal
        case installment
        case financingEnd
    }

    let id: String
    let date: Date
    let title: String
    let amount: Decimal?
    let currencyCode: String
    let kind: Kind

    /// Color resuelto con precedencia: vencido (rojo) > próximo (naranja) > tipo base.
    func color(now: Date = Date()) -> Color {
        Self.resolveColor(kind: kind, date: date, now: now)
    }

    static func resolveColor(kind: Kind, date: Date, now: Date) -> Color {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let eventDay = calendar.startOfDay(for: date)

        if eventDay < startOfToday {
            return .red
        }
        if let days = calendar.dateComponents([.day], from: startOfToday, to: eventDay).day,
           days <= 3, kind != .financingEnd {
            return .orange
        }
        switch kind {
        case .subscriptionRenewal: return .electricBlue
        case .installment: return .appCyan
        case .financingEnd: return .green
        }
    }
}
