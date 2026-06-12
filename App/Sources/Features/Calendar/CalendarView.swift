//
//  CalendarView.swift
//  Subscription Guardian
//
//  Calendario financiero mensual con navegación entre meses, leyenda de
//  colores y lista de eventos del mes.
//

import SwiftUI

struct CalendarView: View {
    @Environment(\.dependencies) private var deps

    @State private var viewModel = CalendarViewModel()

    /// Envoltorio Identifiable para presentar la hoja del día seleccionado.
    private struct SelectedDay: Identifiable {
        let id: Date
    }

    private var selectedDayBinding: Binding<SelectedDay?> {
        Binding(
            get: { viewModel.selectedDay.map(SelectedDay.init) },
            set: { viewModel.selectedDay = $0?.id }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.m) {
                    monthHeader

                    GlassCard {
                        MonthGridView(
                            month: viewModel.displayedMonth,
                            eventsByDay: viewModel.eventsByDay,
                            selectedDay: Binding(
                                get: { viewModel.selectedDay },
                                set: { viewModel.selectedDay = $0 }
                            )
                        )
                    }
                    .transition(.opacity)
                    .id(viewModel.displayedMonth)

                    legend

                    monthEventsList
                }
                .padding(.horizontal, AppSpacing.m)
                .padding(.bottom, AppSpacing.xl)
            }
            .appBackground()
            .navigationTitle(Text("tab.calendar", comment: "Calendario"))
            .sheet(item: selectedDayBinding) { selected in
                DayEventsSheet(day: selected.id, events: viewModel.selectedDayEvents)
            }
        }
        .task {
            viewModel.configure(deps: deps)
            viewModel.load()
        }
    }

    // MARK: - Componentes

    /// Cabecera con el mes visible y flechas de navegación.
    private var monthHeader: some View {
        GlassCard(padding: AppSpacing.s) {
            HStack {
                Button {
                    withAnimation(.spring) { viewModel.previousMonth() }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .frame(width: 40, height: 40)
                }

                Spacer()

                Text(viewModel.displayedMonth, format: .dateTime.month(.wide).year())
                    .font(.headline)
                    .textCase(nil)
                    .contentTransition(.numericText())

                Spacer()

                Button {
                    withAnimation(.spring) { viewModel.nextMonth() }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .frame(width: 40, height: 40)
                }
            }
        }
    }

    /// Leyenda del código de colores del calendario.
    private var legend: some View {
        HStack(spacing: AppSpacing.m) {
            legendItem(
                color: .electricBlue,
                label: String(localized: "calendar.legend.subscriptions", defaultValue: "Suscripciones")
            )
            legendItem(
                color: .green,
                label: String(localized: "calendar.legend.financingEnd", defaultValue: "Fin financiación")
            )
            legendItem(
                color: .orange,
                label: String(localized: "calendar.legend.upcoming", defaultValue: "Próximo")
            )
            legendItem(
                color: .red,
                label: String(localized: "calendar.legend.overdue", defaultValue: "Vencido")
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    /// Lista compacta de los eventos del mes visible.
    private var monthEventsList: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.s) {
                Text("calendar.monthEvents.title", comment: "Eventos del mes")
                    .font(.headline)

                if viewModel.monthEvents.isEmpty {
                    Text("calendar.monthEvents.empty", comment: "Sin eventos este mes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.monthEvents) { event in
                        HStack(spacing: AppSpacing.s) {
                            Circle()
                                .fill(event.color())
                                .frame(width: 7, height: 7)
                            Text(event.date, format: .dateTime.day().month(.abbreviated))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 56, alignment: .leading)
                            Text(event.title)
                                .font(.caption.weight(.medium))
                            Spacer()
                            if let amount = event.amount {
                                Text(amount, format: .currency(code: event.currencyCode))
                                    .font(.caption.bold())
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    CalendarView()
        .environment(\.dependencies, AppDependencies.preview())
}
