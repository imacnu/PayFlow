//
//  MonthlyEvolutionChart.swift
//  Subscription Guardian
//
//  Gráfico de barras con la evolución del gasto mensual de los últimos meses.
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
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.m) {
                Text("dashboard.evolutionChart.title", comment: "Evolución mensual")
                    .font(.headline)

                if points.isEmpty {
                    Text("dashboard.evolutionChart.empty", comment: "Sin histórico todavía")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 100)
                } else {
                    Chart(points, id: \.monthStart) { point in
                        BarMark(
                            x: .value("Mes", point.monthStart, unit: .month),
                            y: .value("Total", doubleValue(point.total))
                        )
                        .foregroundStyle(LinearGradient.appAccent)
                        .cornerRadius(6)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month)) { _ in
                            AxisValueLabel(format: .dateTime.month(.abbreviated))
                        }
                    }
                    .frame(height: 160)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
