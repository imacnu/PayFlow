//
//  DashboardView.swift
//  Subscription Guardian
//
//  Panel principal: KPIs, gráficos de gasto y próximos pagos.
//

import SwiftUI
import SubscriptionGuardianCore

struct DashboardView: View {
    @Environment(\.dependencies) private var deps

    @State private var viewModel = DashboardViewModel()
    @State private var showNotifications = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.m) {
                    kpiGrid

                    CategoryDonutChart(
                        slices: viewModel.categorySlices,
                        total: viewModel.monthlyTotal,
                        currencyCode: viewModel.currencyCode
                    )

                    MonthlyEvolutionChart(
                        points: viewModel.evolution,
                        currencyCode: viewModel.currencyCode
                    )

                    UpcomingPaymentsSection(items: viewModel.upcomingPayments)
                }
                .padding(.horizontal, AppSpacing.m)
                .padding(.bottom, AppSpacing.xl)
            }
            .appBackground()
            .navigationTitle(Text("tab.dashboard", comment: "Panel"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    notificationBell
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel(
                        String(localized: "settings.title", defaultValue: "Ajustes")
                    )
                }
            }
            .sheet(isPresented: $showNotifications, onDismiss: { viewModel.load() }) {
                NotificationCenterView()
            }
            .sheet(isPresented: $showSettings, onDismiss: { viewModel.load() }) {
                SettingsView()
            }
            .refreshable { viewModel.load() }
        }
        .task {
            viewModel.configure(deps: deps)
            viewModel.load()
        }
    }

    // MARK: - Componentes

    /// Campana de notificaciones con contador de no leídas.
    private var notificationBell: some View {
        Button {
            showNotifications = true
        } label: {
            Image(systemName: "bell.fill")
                .overlay(alignment: .topTrailing) {
                    if viewModel.unreadNotifications > 0 {
                        Text("\(min(viewModel.unreadNotifications, 9))")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(4)
                            .background(Circle().fill(.red))
                            .offset(x: 8, y: -8)
                    }
                }
        }
        .accessibilityLabel(
            String(localized: "dashboard.notifications", defaultValue: "Notificaciones")
        )
    }

    /// Rejilla de indicadores clave (2 columnas).
    private var kpiGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.m) {
            KPICard(
                title: String(localized: "dashboard.kpi.monthlySpend", defaultValue: "Gasto mensual"),
                value: viewModel.monthlyTotal.formatted(.currency(code: viewModel.currencyCode)),
                icon: "eurosign.circle.fill",
                tint: .electricBlue
            )
            KPICard(
                title: String(localized: "dashboard.kpi.activeSubscriptions", defaultValue: "Suscripciones"),
                value: "\(viewModel.activeSubscriptionsCount)",
                icon: "square.stack.3d.up.fill",
                tint: .appCyan
            )
            KPICard(
                title: String(localized: "dashboard.kpi.activeFinancings", defaultValue: "Financiaciones"),
                value: "\(viewModel.activeFinancingsCount)",
                icon: "creditcard.fill",
                tint: .purple
            )
            KPICard(
                title: String(localized: "dashboard.kpi.potentialSaving", defaultValue: "Ahorro potencial"),
                value: String(
                    localized: "dashboard.kpi.potentialSavingValue",
                    defaultValue: "\(viewModel.potentialSaving.formatted(.currency(code: viewModel.currencyCode)))/año"
                ),
                icon: "leaf.fill",
                tint: .green
            )
        }
        .animation(.spring, value: viewModel.monthlyTotal)
    }
}

#Preview {
    DashboardView()
        .environment(\.dependencies, AppDependencies.preview())
}
