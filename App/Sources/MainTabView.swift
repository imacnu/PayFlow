import SwiftUI

/// Pestañas principales de la app. Las vistas de cada pestaña
/// (`DashboardView`, `SubscriptionListView`, etc.) las aportan los
/// módulos de cada funcionalidad en la integración.
struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label(
                        String(localized: "tab.dashboard", defaultValue: "Panel"),
                        systemImage: "chart.pie.fill"
                    )
                }

            SubscriptionListView()
                .tabItem {
                    Label(
                        String(localized: "tab.subscriptions", defaultValue: "Suscripciones"),
                        systemImage: "square.stack.3d.up.fill"
                    )
                }

            FinancingListView()
                .tabItem {
                    Label(
                        String(localized: "tab.financing", defaultValue: "Financiación"),
                        systemImage: "creditcard.fill"
                    )
                }

            CalendarView()
                .tabItem {
                    Label(
                        String(localized: "tab.calendar", defaultValue: "Calendario"),
                        systemImage: "calendar"
                    )
                }

            InsightsView()
                .tabItem {
                    Label(
                        String(localized: "tab.insights", defaultValue: "Insights"),
                        systemImage: "lightbulb.fill"
                    )
                }
        }
    }
}
