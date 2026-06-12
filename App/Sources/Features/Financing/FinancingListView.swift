//
//  FinancingListView.swift
//  Subscription Guardian
//
//  Lista de financiaciones BNPL con resumen agregado, progreso por
//  financiación y alta de nuevas financiaciones.
//

import SwiftUI
import SubscriptionGuardianCore

struct FinancingListView: View {
    @Environment(\.dependencies) private var deps

    @State private var viewModel = FinancingViewModel()
    @State private var showCreateForm = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.financings.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .appBackground()
            .navigationTitle(Text("financing.title", comment: "Título de la pestaña de financiación"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(
                        String(localized: "financing.add", defaultValue: "Añadir financiación")
                    )
                }
            }
            .sheet(isPresented: $showCreateForm, onDismiss: { viewModel.load() }) {
                FinancingFormView(mode: .create)
            }
            .sheet(isPresented: $viewModel.showPaywall) {
                PaywallView()
            }
        }
        .task {
            viewModel.configure(deps: deps)
            viewModel.load()
        }
        .onChange(of: showCreateForm) { _, isPresented in
            if !isPresented { viewModel.load() }
        }
    }

    // MARK: - Contenido

    private var content: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.m) {
                summaryHeader
                    .cascadeIn(0)

                ForEach(viewModel.financings, id: \.id) { financing in
                    NavigationLink {
                        FinancingDetailView(financing: financing)
                    } label: {
                        FinancingRowView(financing: financing)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.delete(financing)
                        } label: {
                            Label(
                                String(localized: "common.delete", defaultValue: "Eliminar"),
                                systemImage: "trash"
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.m)
            .padding(.bottom, AppSpacing.xxl + AppSpacing.l)
        }
        .refreshable { viewModel.load() }
    }

    /// Cabecera con el capital pendiente total y el compromiso mensual.
    private var summaryHeader: some View {
        GlassCard {
            HStack(spacing: AppSpacing.l) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("financing.summary.pendingCapital", comment: "Capital pendiente")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    CurrencyText(amount: viewModel.totalPendingCapital, currencyCode: "EUR")
                        .animation(.spring, value: viewModel.totalPendingCapital)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("financing.summary.monthly", comment: "Compromiso mensual")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    CurrencyText(
                        amount: viewModel.monthlyCommitment,
                        currencyCode: "EUR",
                        font: .title3.bold()
                    )
                    PillBadge(
                        text: String(
                            localized: "financing.summary.activeCount",
                            defaultValue: "\(viewModel.activeCount) activas"
                        ),
                        tint: .appCyan
                    )
                }
            }
        }
    }

    /// Vacío que vende la utilidad: alivio y control, no descripción literal.
    private var emptyState: some View {
        EmptyStateView(
            icon: "creditcard.fill",
            title: String(
                localized: "financing.empty.title",
                defaultValue: "Tus plazos, en claridad total"
            ),
            message: String(
                localized: "financing.empty.message",
                defaultValue: "Añade un plan (Klarna, Aplazame…) y sigue cada cuota con una vista limpia, visual y sin sorpresas."
            ),
            actionTitle: String(localized: "financing.add", defaultValue: "Añadir financiación"),
            action: { showCreateForm = true }
        )
    }
}

/// Fila de una financiación: comercio, proveedor, progreso y cuota mensual.
struct FinancingRowView: View {
    let financing: Financing

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(financing.merchant)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    PillBadge(text: financing.provider.localizedName, tint: .electricBlue)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    CurrencyText(
                        amount: financing.monthlyAmount,
                        currencyCode: "EUR",
                        font: .headline
                    )
                    Text("financing.row.perMonth", comment: "al mes")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            AnimatedProgressBar(
                progress: financing.progress,
                tint: financing.status == .completed ? .appLime : .appCyan
            )

            HStack {
                Text(
                    String(
                        localized: "financing.row.progress",
                        defaultValue: "\(financing.paidInstallments) de \(financing.totalInstallments) cuotas pagadas"
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Spacer()

                if financing.status == .completed {
                    PillBadge(
                        text: String(localized: "financing.status.completed", defaultValue: "Completada"),
                        tint: .appLime
                    )
                } else if let next = financing.nextInstallmentDate {
                    Text(next, format: .dateTime.day().month(.abbreviated))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .glassCard()
    }
}

#Preview {
    FinancingListView()
        .environment(\.dependencies, AppDependencies.preview())
}
