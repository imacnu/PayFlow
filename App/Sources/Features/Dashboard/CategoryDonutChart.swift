//
//  CategoryDonutChart.swift
//  Subscription Guardian
//
//  Anillo de luz del gasto mensual por categoría: el importe central es el
//  protagonista absoluto, con leyenda editorial y estado latente cuando
//  todavía no hay datos.
//

import SwiftUI
import Charts
import SubscriptionGuardianCore

struct CategoryDonutChart: View {
    let slices: [SpendingCalculator.CategorySlice]
    let total: Decimal
    let currencyCode: String

    /// Progreso de la animación de aparición del anillo.
    @State private var revealed = false

    /// Conversión segura Decimal → Double para Swift Charts.
    private func doubleValue(_ value: Decimal) -> Double {
        NSDecimalNumber(decimal: value).doubleValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            Text("dashboard.categoryChart.title", comment: "Gasto por categoría")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if slices.isEmpty {
                latentState
            } else {
                ring
                legend
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    // MARK: - Anillo de luz

    private var ring: some View {
        ZStack {
            // Halo difuso tras el anillo: el gráfico emite luz.
            Circle()
                .fill(Color.appCyan.opacity(0.12))
                .frame(width: 170, height: 170)
                .blur(radius: 30)

            Chart(slices) { slice in
                SectorMark(
                    angle: .value("Importe", doubleValue(slice.monthlyAmount)),
                    innerRadius: .ratio(0.72),
                    angularInset: 2
                )
                .foregroundStyle(slice.category.tintColor)
                .cornerRadius(6)
            }
            .frame(height: 210)

            // Total mensual: protagonista absoluto del módulo.
            VStack(spacing: 2) {
                CurrencyText(
                    amount: total,
                    currencyCode: currencyCode,
                    font: .system(.largeTitle, design: .rounded).bold()
                )
                Text("dashboard.categoryChart.perMonth", comment: "al mes")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .scaleEffect(revealed ? 1 : 0.88)
        .opacity(revealed ? 1 : 0)
        .onAppear {
            withAnimation(AppMotion.expressive) { revealed = true }
        }
    }

    /// Leyenda editorial: nombre con presencia, importe alineado a la derecha.
    private var legend: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            ForEach(slices.prefix(6)) { slice in
                HStack(spacing: AppSpacing.s) {
                    Circle()
                        .fill(slice.category.tintColor)
                        .frame(width: 7, height: 7)
                        .glow(slice.category.tintColor, radius: 4, opacity: 0.5)
                    Text(slice.category.localizedName)
                        .font(.caption.weight(.medium))
                    Spacer()
                    Text(slice.monthlyAmount, format: .currency(code: currencyCode))
                        .font(.system(.caption, design: .rounded).bold())
                }
            }
        }
    }

    // MARK: - Estado latente

    /// Versión latente de la tarjeta: el vacío no parece muerto, anticipa
    /// lo que la pantalla será cuando haya datos.
    private var latentState: some View {
        VStack(spacing: AppSpacing.m) {
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient.appAccent.opacity(0.25),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(Color.appCyan.opacity(0.7))
            }

            Text(
                "dashboard.categoryChart.empty",
                comment: "Tu mapa de gasto por categorías aparecerá aquí."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
    }
}
