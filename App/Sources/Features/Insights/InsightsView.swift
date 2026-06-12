//
//  InsightsView.swift
//  Subscription Guardian
//
//  Analítica mensual y recomendaciones de ahorro.
//

import SwiftUI
import SubscriptionGuardianCore

struct InsightsView: View {
    @Environment(\.dependencies) private var deps

    @State private var viewModel = InsightsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.m) {
                    summaryCard

                    if viewModel.totalPotentialSaving > 0 {
                        savingsBanner
                    }

                    if viewModel.insights.isEmpty {
                        EmptyStateView(
                            icon: "checkmark.seal.fill",
                            title: String(localized: "insights.empty.title", defaultValue: "Todo en orden"),
                            message: String(
                                localized: "insights.empty.message",
                                defaultValue: "No hemos detectado oportunidades de ahorro. ¡Buen trabajo!"
                            )
                        )
                        .padding(.top, AppSpacing.l)
                    } else {
                        ForEach(viewModel.insights) { insight in
                            InsightCardView(insight: insight, currencyCode: viewModel.currencyCode)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.m)
                .padding(.bottom, AppSpacing.xl)
            }
            .appBackground()
            .navigationTitle(Text("tab.insights", comment: "Insights"))
            .refreshable { viewModel.load() }
        }
        .task {
            viewModel.configure(deps: deps)
            viewModel.load()
        }
    }

    // MARK: - Componentes

    /// Resumen: gasto mensual, proyección anual y variación intermensual.
    private var summaryCard: some View {
        GlassCard {
            VStack(spacing: AppSpacing.m) {
                HStack(spacing: AppSpacing.l) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("insights.summary.monthly", comment: "Gasto mensual")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        CurrencyText(amount: viewModel.monthlyTotal, currencyCode: viewModel.currencyCode)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("insights.summary.annual", comment: "Proyección anual")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        CurrencyText(
                            amount: viewModel.projectedAnnual,
                            currencyCode: viewModel.currencyCode,
                            font: .title3.bold()
                        )
                    }
                }

                if let variation = viewModel.monthlyVariation {
                    variationRow(variation)
                }

                if let top = viewModel.categorySlices.first {
                    HStack {
                        Text("insights.summary.topCategory", comment: "Categoría más costosa")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        PillBadge(text: top.category.localizedName, tint: top.category.tintColor)
                        Text(top.monthlyAmount, format: .currency(code: viewModel.currencyCode))
                            .font(.caption.bold())
                    }
                }
            }
        }
    }

    /// Fila de variación intermensual con flecha y color semántico.
    private func variationRow(_ variation: Decimal) -> some View {
        let increased = variation > 0
        return HStack {
            Text("insights.summary.variation", comment: "Variación mensual")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Image(systemName: increased ? "arrow.up.right" : "arrow.down.right")
                .font(.caption.bold())
            Text("\(variation)%")
                .font(.caption.bold())
        }
        .foregroundStyle(increased ? Color.orange : Color.green)
    }

    /// Banner principal de ahorro potencial.
    private var savingsBanner: some View {
        GlassCard {
            HStack(spacing: AppSpacing.m) {
                Image(systemName: "leaf.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(LinearGradient.appAccent))

                VStack(alignment: .leading, spacing: 2) {
                    Text(
                        String(
                            localized: "insights.banner.title",
                            defaultValue: "Podrías ahorrar \(viewModel.totalPotentialSaving.formatted(.currency(code: viewModel.currencyCode)))/año"
                        )
                    )
                    .font(.headline)
                    Text("insights.banner.subtitle", comment: "Revisa las recomendaciones siguientes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
        }
    }
}

#Preview {
    InsightsView()
        .environment(\.dependencies, AppDependencies.preview())
}
