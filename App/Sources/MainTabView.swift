import SwiftUI

/// Pestañas principales de la app con navegación inferior flotante en
/// cápsula de cristal: blur, borde translúcido y tab activo con glow cian.
struct MainTabView: View {
    /// Identidad de cada pestaña.
    enum Tab: Int, CaseIterable, Identifiable {
        case dashboard, subscriptions, financing, calendar, insights

        var id: Int { rawValue }

        /// Símbolo SF de la pestaña (iconografía coherente de producto).
        var symbol: String {
            switch self {
            case .dashboard: return "square.grid.2x2.fill"
            case .subscriptions: return "repeat"
            case .financing: return "creditcard.fill"
            case .calendar: return "calendar"
            case .insights: return "sparkles"
            }
        }

        /// Título corto localizado de la pestaña.
        var title: String {
            switch self {
            case .dashboard:
                return String(localized: "tab.dashboard", defaultValue: "Panel")
            case .subscriptions:
                return String(localized: "tab.subscriptions", defaultValue: "Suscripciones")
            case .financing:
                return String(localized: "tab.financing", defaultValue: "Financiación")
            case .calendar:
                return String(localized: "tab.calendar", defaultValue: "Calendario")
            case .insights:
                return String(localized: "tab.insights", defaultValue: "Insights")
            }
        }
    }

    @State private var selection: Tab = .dashboard

    @Environment(\.colorScheme) private var colorScheme

    /// Espacio de nombres para el deslizamiento del indicador activo.
    @Namespace private var tabIndicator

    /// Color de los destinos en reposo. Color explícito y legible: los
    /// estilos semánticos pierden contraste sobre el material translúcido.
    private var restingColor: Color {
        colorScheme == .dark ? Color.appMuted : Color(hex: "5A6E80")
    }

    /// Color del destino activo: texto claro del mockup, no cian.
    private var activeColor: Color {
        colorScheme == .dark ? Color(hex: "F5FDFF") : Color(hex: "0A2A38")
    }

    var body: some View {
        // Contenedor propio en lugar de TabView: evita la barra del sistema
        // y mantiene vivo el estado de cada pestaña entre cambios.
        ZStack {
            tabContent(DashboardView(), tab: .dashboard)
            tabContent(SubscriptionListView(), tab: .subscriptions)
            tabContent(FinancingListView(), tab: .financing)
            tabContent(CalendarView(), tab: .calendar)
            tabContent(InsightsView(), tab: .insights)
        }
        .overlay(alignment: .bottom) {
            floatingTabBar
        }
    }

    /// Cada pestaña permanece montada; solo la activa es visible e
    /// interactiva, lo que conserva scroll y estado al volver. El cambio se
    /// percibe como desplazamiento lateral suave con ligera profundidad.
    private func tabContent(_ view: some View, tab: Tab) -> some View {
        let isActive = selection == tab
        let direction: CGFloat = tab.rawValue < selection.rawValue ? -1 : 1

        return view
            .opacity(isActive ? 1 : 0)
            .offset(x: isActive ? 0 : direction * 24)
            .scaleEffect(isActive ? 1 : 0.98)
            .allowsHitTesting(isActive)
            .accessibilityHidden(!isActive)
    }

    // MARK: - Barra flotante

    /// Cápsula de cristal con los cinco destinos. El tab activo se marca con
    /// un fondo interno deslizante y glow cian; el resto queda en reposo.
    private var floatingTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, AppSpacing.s)
        .padding(.vertical, AppSpacing.s)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.35), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .floatingShadow()
        .padding(.horizontal, AppSpacing.m)
        .padding(.bottom, AppSpacing.s)
    }

    /// Destino de la barra: icono en cápsula + etiqueta corta, siempre
    /// visibles. El activo se incrusta en una cápsula de vidrio con glow
    /// cian; el resto queda en un tono apagado pero perfectamente legible.
    private func tabButton(_ tab: Tab) -> some View {
        let isActive = selection == tab

        return Button {
            withAnimation(AppMotion.standard) {
                selection = tab
            }
        } label: {
            VStack(spacing: 5) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(isActive ? activeColor : restingColor)
                    .frame(width: 42, height: 30)
                    .background {
                        if isActive {
                            RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.appCyanDeep.opacity(0.26),
                                            Color.appTeal.opacity(0.16)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .matchedGeometryEffect(id: "activeTab", in: tabIndicator)
                        }
                    }
                    .glow(isActive ? .appCyan : .clear, radius: 10, opacity: isActive ? 0.4 : 0)

                Text(tab.title)
                    .font(.system(size: 10, weight: isActive ? .semibold : .medium))
                    .foregroundStyle(isActive ? activeColor : restingColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressableCard)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

#Preview {
    MainTabView()
        .environment(\.dependencies, AppDependencies.preview())
}
