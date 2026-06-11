import SwiftUI
import Foundation
import SubscriptionGuardianCore

// MARK: - Utilidades

/// Convierte un `Decimal` a `Double` para vistas que lo requieren (ProgressView, etc.).
func doubleValue(_ value: Decimal) -> Double {
    NSDecimalNumber(decimal: value).doubleValue
}

// MARK: - Categorías

/// Color asociado a cada categoría de servicio.
func categoryColor(_ category: ServiceCategory) -> Color {
    switch category {
    case .streaming: return .red
    case .ai: return .teal
    case .productivity: return WidgetConfig.electricBlue
    case .music: return .green
    case .finance: return .orange
    case .fitness: return .pink
    case .insurance: return .indigo
    case .membership: return .purple
    case .other: return .gray
    }
}

/// Nombre localizado para mostrar de cada categoría de servicio.
func categoryDisplayName(_ category: ServiceCategory) -> String {
    switch category {
    case .streaming:
        return String(localized: "category.streaming", defaultValue: "Streaming")
    case .ai:
        return String(localized: "category.ai", defaultValue: "IA")
    case .productivity:
        return String(localized: "category.productivity", defaultValue: "Productividad")
    case .music:
        return String(localized: "category.music", defaultValue: "Música")
    case .finance:
        return String(localized: "category.finance", defaultValue: "Finanzas")
    case .fitness:
        return String(localized: "category.fitness", defaultValue: "Fitness")
    case .insurance:
        return String(localized: "category.insurance", defaultValue: "Seguros")
    case .membership:
        return String(localized: "category.membership", defaultValue: "Membresías")
    case .other:
        return String(localized: "category.other", defaultValue: "Otros")
    }
}

/// Punto de color que identifica una categoría.
struct CategoryDot: View {
    let category: ServiceCategory

    var body: some View {
        Circle()
            .fill(categoryColor(category))
            .frame(width: 8, height: 8)
    }
}

// MARK: - Fondo común

/// Fondo común de los widgets del sistema: degradado suave con los acentos
/// de la app sobre un material. No se usa glassEffect en widgets;
/// el fondo se aplica con `containerBackground(for: .widget)`.
struct WidgetBackground: ViewModifier {
    func body(content: Content) -> some View {
        content.containerBackground(for: .widget) {
            ZStack {
                Rectangle()
                    .fill(.regularMaterial)
                LinearGradient(
                    colors: [
                        WidgetConfig.electricBlue.opacity(0.18),
                        WidgetConfig.appCyan.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}
