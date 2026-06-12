//
//  CategoryDonutChart.swift
//  Subscription Guardian
//
//  Gráfico circular (donut) del gasto mensual por categoría, con el total
//  en el centro y leyenda de categorías.
//

import SwiftUI
import Charts
import SubscriptionGuardianCore

struct CategoryDonutChart: View {
    let slices: [SpendingCalculator.CategorySlice]
    let total: Decimal
    let currencyCode: String

    /// Conversión segura Decimal → Double para Swift Charts.
    private func doubleValue(_ value: Decimal) -> Double {
        NSDecimalNumber(decimal: value).doubleValue
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.m) {
                Text("dashboard.categoryChart.title", comment: "Gasto por categoría")
                    .font(.headline)

                if slices.isEmpty {
                    Text("dashboard.categoryChart.empty", comment: "Sin datos de categorías")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 120)
                } else {
                    ZStack {
                        Chart(slices) { slice in
                            SectorMark(
                                angle: .value("Importe", doubleValue(slice.monthlyAmount)),
                                innerRadius: .ratio(0.62),
                                angularInset: 1.5
                            )
                            .foregroundStyle(slice.category.tintColor)
                            .cornerRadius(4)
                        }
                        .frame(height: 200)

                        // Total mensual en el centro del donut.
                        VStack(spacing: 2) {
                            CurrencyText(amount: total, currencyCode: currencyCode, font: .title3.bold())
                            Text("dashboard.categoryChart.perMonth", comment: "al mes")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    legend
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Leyenda compacta: punto de color + nombre + importe.
    private var legend: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(slices.prefix(6)) { slice in
                HStack(spacing: AppSpacing.s) {
                    Circle()
                        .fill(slice.category.tintColor)
                        .frame(width: 8, height: 8)
                    Text(slice.category.localizedName)
                        .font(.caption)
                    Spacer()
                    Text(slice.monthlyAmount, format: .currency(code: currencyCode))
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
