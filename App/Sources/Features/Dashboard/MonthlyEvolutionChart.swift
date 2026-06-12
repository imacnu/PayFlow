//
//  MonthlyEvolutionChart.swift
//  Subscription Guardian
//
//  Evolución del gasto mensual como columnas luminosas: la rejilla casi
//  desaparece y queda solo la referencia necesaria.
//

import SwiftUI
import Charts
import SubscriptionGuardianCore

struct MonthlyEvolutionChart: View {
    let points: [SpendingCalculator.MonthPoint]
    let currencyCode: String

    /// Conversión segura Decimal → Double para Swift Charts.
    private func doubleValue(_ value: Decimal) -> Double {
        NSDecimalNumber(decimal: value).doubleValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            Text("dashboard.evolutionChart.title", comment: "Evolución mensual")
                .font(.system(size: 15, weight: .bold))

            if points.isEmpty {
                Text(
                    "dashboard.evolutionChart.empty",
                    comment: "Tu evolución mensual se dibujará aquí con el tiempo."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                Chart(points, id: \.monthStart) { point in
                    BarMark(
                        x: .value("Mes", point.monthStart, unit: .month),
                        y: .value("Total", doubleValue(point.total)),
                        width: .ratio(0.45)
                    )
                    .foregroundStyle(LinearGradient.luminousColumn)
                    .cornerRadius(8)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                            .font(.caption2)
                            .foregroundStyle(Color.secondary)
                    }
                }
                // Rejilla mínima: solo la referencia necesaria, sin ruido.
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                        AxisGridLine()
                            .foregroundStyle(Color.white.opacity(0.06))
                        AxisValueLabel()
                            .font(.caption2)
                            .foregroundStyle(Color.secondary.opacity(0.7))
                    }
                }
                .frame(height: 160)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}
