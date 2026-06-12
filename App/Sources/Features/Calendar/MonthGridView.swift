//
//  MonthGridView.swift
//  Subscription Guardian
//
//  Cuadrícula mensual construida a mano: cabecera de días de la semana y
//  celdas con número de día + puntos de color por evento.
//

import SwiftUI

struct MonthGridView: View {
    let month: Date
    let eventsByDay: [Date: [CalendarEvent]]
    @Binding var selectedDay: Date?

    private let calendar = Calendar.current

    /// Días del mes precedidos por huecos para alinear el primer día
    /// con su columna de la semana (respetando firstWeekday del locale).
    private var dayCells: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let dayCount = calendar.range(of: .day, in: .month, for: month)?.count else {
            return []
        }
        let firstDay = monthInterval.start
        let weekdayOfFirst = calendar.component(.weekday, from: firstDay)
        let leadingBlanks = (weekdayOfFirst - calendar.firstWeekday + 7) % 7

        var cells: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for offset in 0..<dayCount {
            cells.append(calendar.date(byAdding: .day, value: offset, to: firstDay))
        }
        return cells
    }

    /// Símbolos cortos de los días de la semana, rotados según firstWeekday.
    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    var body: some View {
        VStack(spacing: AppSpacing.s) {
            // Cabecera de días de la semana.
            HStack {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol.uppercased())
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                ForEach(Array(dayCells.enumerated()), id: \.offset) { _, day in
                    if let day {
                        dayCell(for: day)
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
        }
    }

    private func dayCell(for day: Date) -> some View {
        let dayStart = calendar.startOfDay(for: day)
        let events = eventsByDay[dayStart] ?? []
        let isToday = calendar.isDateInToday(day)
        let isSelected = selectedDay.map { calendar.isDate($0, inSameDayAs: day) } ?? false

        return Button {
            selectedDay = day
        } label: {
            VStack(spacing: 3) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.callout.weight(isToday ? .bold : .regular))
                    .foregroundStyle(isToday ? Color.white : Color.primary)
                    .frame(width: 30, height: 30)
                    .background {
                        if isToday {
                            Circle().fill(LinearGradient.appAccent)
                        } else if isSelected {
                            Circle().stroke(Color.electricBlue, lineWidth: 1.5)
                        }
                    }

                // Hasta 3 puntos de color por día.
                HStack(spacing: 3) {
                    ForEach(events.prefix(3), id: \.id) { event in
                        Circle()
                            .fill(event.color())
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 6)
            }
            .frame(height: 44)
        }
        .buttonStyle(.plain)
        .disabled(events.isEmpty)
    }
}
