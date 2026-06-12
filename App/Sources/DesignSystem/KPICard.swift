//
//  KPICard.swift
//  Subscription Guardian
//
//  Tarjeta de indicador clave (KPI): el valor numérico es el protagonista
//  absoluto; icono y label quedan en reposo. Glow semántico opcional.
//

import SwiftUI

/// Tarjeta de vidrio que muestra un indicador clave con tendencia opcional.
struct KPICard: View {
    /// Tendencia del indicador con su texto asociado.
    enum Trend {
        case up(String)
        case down(String)
        case neutral(String)

        /// Símbolo SF asociado a la tendencia.
        var symbol: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }

        /// Texto asociado a la tendencia.
        var text: String {
            switch self {
            case .up(let text), .down(let text), .neutral(let text):
                return text
            }
        }

        /// Color semántico: subir gasto = ámbar, bajar = lima, neutral = gris.
        var color: Color {
            switch self {
            case .up: return .appAmber
            case .down: return .appLime
            case .neutral: return .secondary
            }
        }
    }

    let title: String
    let value: String
    /// Nombre de un SF Symbol.
    let icon: String
    let tint: Color
    var trend: Trend? = nil
    /// Activa el glow semántico de la tarjeta (solo KPIs con significado).
    var glows: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            // Label e icono en reposo: pierden protagonismo sin perder lectura.
            HStack(spacing: AppSpacing.s) {
                Image(systemName: icon)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(tint.opacity(0.85))

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)
            }

            // El importe domina la tarjeta.
            Text(value)
                .font(.system(.title2, design: .rounded).bold())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())

            // Píldora de tendencia opcional.
            if let trend {
                HStack(spacing: 4) {
                    Image(systemName: trend.symbol)
                    Text(trend.text)
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(trend.color)
                .padding(.horizontal, AppSpacing.s)
                .padding(.vertical, 4)
                .background(trend.color.opacity(0.12), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(glow: glows ? tint : nil)
    }
}

// MARK: - Vista previa

#Preview {
    ZStack {
        AppBackground()

        VStack(spacing: AppSpacing.m) {
            KPICard(
                title: "Monthly spend",
                value: "$42.97",
                icon: "creditcard.fill",
                tint: .appCyan,
                trend: .up("+12% vs last month"),
                glows: true
            )

            KPICard(
                title: "Active subscriptions",
                value: "8",
                icon: "checklist",
                tint: .appCyan,
                trend: .down("-2 this month")
            )

            KPICard(
                title: "Next renewal",
                value: "3 days",
                icon: "calendar",
                tint: .appAmber
            )
        }
        .padding(AppSpacing.l)
    }
    .preferredColorScheme(.dark)
}
