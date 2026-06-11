//
//  KPICard.swift
//  Subscription Guardian
//
//  Tarjeta de indicador clave (KPI) con icono, título, valor y tendencia opcional.
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

        /// Color semántico: subir gasto = naranja, bajar = verde, neutral = gris.
        var color: Color {
            switch self {
            case .up: return .orange
            case .down: return .green
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

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            HStack(spacing: AppSpacing.s) {
                // Icono dentro de un círculo teñido.
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(tint)
                }

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }

            Text(value)
                .font(.title2.bold())
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
        .glassCard()
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
                tint: .electricBlue,
                trend: .up("+12% vs last month")
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
                tint: .orange
            )
        }
        .padding(AppSpacing.l)
    }
}
