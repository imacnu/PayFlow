//
//  CalendarView.swift
//  Subscription Guardian
//
//  Calendario financiero: cuadrícula de tiempo iluminada, silenciosa y
//  precisa. Cápsula de mes protagonista, leyenda con respiración sutil y
//  eventos del mes integrados en el mismo sistema visual.
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
                        .cascadeIn(0)

                    MonthGridView(
                        month: viewModel.displayedMonth,
                        eventsByDay: viewModel.eventsByDay,
                        selectedDay: Binding(
                            get: { viewModel.selectedDay },
                            set: { viewModel.selectedDay = $0 }
                        )
                    )
                    .glassCard()
                    .transition(.opacity)
                    .id(viewModel.displayedMonth)
                    .cascadeIn(1)

                    legend
                        .cascadeIn(2)

                    monthEventsList
                        .cascadeIn(3)
                }
                .padding(.horizontal, AppSpacing.m)
                .padding(.bottom, AppSpacing.xxl + AppSpacing.l)
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

    /// Cápsula protagonista con el mes visible y navegación táctil.
    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation(AppMotion.standard) { viewModel.previousMonth() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(Color.appCyan)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.pressableCard)

            Spacer()

            Text(viewModel.displayedMonth, format: .dateTime.month(.wide).year())
                .font(.system(.headline, design: .rounded).bold())
                .textCase(nil)
                .contentTransition(.numericText())

            Spacer()

            Button {
                withAnimation(AppMotion.standard) { viewModel.nextMonth() }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(Color.appCyan)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.pressableCard)
        }
        .glassCard(cornerRadius: AppRadius.large, padding: AppSpacing.s)
    }

    /// Leyenda del código de colores con respiración sutil en los puntos.
    private var legend: some View {
        HStack(spacing: AppSpacing.m) {
            legendItem(
                color: .electricBlue,
                label: String(localized: "calendar.legend.subscriptions", defaultValue: "Suscripciones")
            )
            legendItem(
                color: .appLime,
                label: String(localized: "calendar.legend.financingEnd", defaultValue: "Fin financiación")
            )
            legendItem(
                color: .appAmber,
                label: String(localized: "calendar.legend.upcoming", defaultValue: "Próximo")
            )
            legendItem(
                color: .appMagenta,
                label: String(localized: "calendar.legend.overdue", defaultValue: "Vencido")
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            BreathingDot(color: color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    /// Lista compacta de los eventos del mes visible.
    private var monthEventsList: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text("calendar.monthEvents.title", comment: "Eventos del mes")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if viewModel.monthEvents.isEmpty {
                // Vacío en calma: orden y silencio, no ausencia.
                HStack(spacing: AppSpacing.s) {
                    Image(systemName: "moon.stars.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.appCyan.opacity(0.7))
                    Text("calendar.monthEvents.empty", comment: "Un mes tranquilo: sin cargos previstos.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, AppSpacing.xxs)
            } else {
                ForEach(viewModel.monthEvents) { event in
                    HStack(spacing: AppSpacing.s) {
                        Circle()
                            .fill(event.color())
                            .frame(width: 7, height: 7)
                            .glow(event.color(), radius: 4, opacity: 0.5)
                        Text(event.date, format: .dateTime.day().month(.abbreviated))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 56, alignment: .leading)
                        Text(event.title)
                            .font(.caption.weight(.medium))
                        Spacer()
                        if let amount = event.amount {
                            Text(amount, format: .currency(code: event.currencyCode))
                                .font(.system(.caption, design: .rounded).bold())
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

/// Punto de leyenda con respiración muy controlada, sin distraer.
private struct BreathingDot: View {
    let color: Color

    @State private var breathing = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 7, height: 7)
            .glow(color, radius: 4, opacity: breathing ? 0.6 : 0.25)
            .scaleEffect(breathing ? 1.1 : 0.95)
            .animation(
                .easeInOut(duration: 2.4).repeatForever(autoreverses: true),
                value: breathing
            )
            .onAppear { breathing = true }
    }
}

#Preview {
    CalendarView()
        .environment(\.dependencies, AppDependencies.preview())
}
