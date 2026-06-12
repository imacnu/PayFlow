//
//  SubscriptionListView.swift
//  Subscription Guardian
//
//  Lista principal de suscripciones con cabecera de totales, búsqueda
//  y acceso al detalle y al formulario de alta.
//

import SwiftUI
import SubscriptionGuardianCore

/// Pestaña de suscripciones: cabecera con totales y lista de tarjetas.
struct SubscriptionListView: View {
    @Environment(\.dependencies) private var deps

    @State private var viewModel = SubscriptionsViewModel()
    @State private var showCreateForm = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.subscriptions.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .appBackground()
            .navigationTitle(String(
                localized: "subscriptions.title",
                defaultValue: "Suscripciones"
            ))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(String(
                        localized: "subscriptions.add",
                        defaultValue: "Añadir suscripción"
                    ))
                }
            }
            .sheet(isPresented: $showCreateForm, onDismiss: { viewModel.load() }) {
                SubscriptionFormView(mode: .create)
            }
        }
        .task {
            viewModel.configure(deps: deps)
            viewModel.load()
        }
        .onAppear {
            // Refresca al volver de pantallas que pueden haber mutado datos.
            viewModel.load()
        }
    }

    // MARK: - Contenido

    private var content: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.m) {
                header
                    .cascadeIn(0)

                ForEach(viewModel.filteredSubscriptions, id: \.id) { subscription in
                    NavigationLink {
                        SubscriptionDetailView(subscription: subscription)
                    } label: {
                        SubscriptionRowView(subscription: subscription)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.delete(subscription)
                        } label: {
                            Label(
                                String(localized: "common.delete", defaultValue: "Eliminar"),
                                systemImage: "trash"
                            )
                        }
                    }
                }
            }
            .padding(AppSpacing.m)
            .padding(.bottom, AppSpacing.xxl + AppSpacing.l)
        }
        .searchable(
            text: $viewModel.searchText,
            prompt: Text(String(
                localized: "subscriptions.search",
                defaultValue: "Buscar suscripción"
            ))
        )
    }

    /// Cabecera con el gasto mensual total y el número de activas.
    private var header: some View {
        GlassCard {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(
                        localized: "subscriptions.header.monthly",
                        defaultValue: "Gasto mensual"
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    CurrencyText(
                        amount: viewModel.monthlyTotal,
                        currencyCode: viewModel.displayCurrencyCode
                    )
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(
                        localized: "subscriptions.header.active",
                        defaultValue: "Activas"
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Text("\(viewModel.activeCount)")
                        .font(.title2.bold())
                        .contentTransition(.numericText())
                }
            }
        }
    }

    /// Vacío inspirador: construye valor percibido desde el primer uso.
    private var emptyState: some View {
        EmptyStateView(
            icon: "square.stack.3d.up.fill",
            title: String(
                localized: "subscriptions.empty.title",
                defaultValue: "Tu panel aún no cuenta tu historia"
            ),
            message: String(
                localized: "subscriptions.empty.message",
                defaultValue: "Añade tus primeras suscripciones para descubrir patrones, ahorros y próximos cobros en un panel que se siente vivo."
            ),
            actionTitle: String(
                localized: "subscriptions.empty.action",
                defaultValue: "Añadir suscripción"
            ),
            actionIcon: "sparkles",
            action: { showCreateForm = true }
        )
    }
}

// MARK: - Fila de suscripción

/// Tarjeta de una suscripción dentro de la lista.
struct SubscriptionRowView: View {
    let subscription: Subscription

    var body: some View {
        HStack(spacing: AppSpacing.m) {
            BrandIconView(
                symbol: subscription.iconSymbol,
                monogram: subscription.monogram,
                colorHex: subscription.colorHex
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: AppSpacing.s) {
                    PillBadge(
                        text: subscription.category.localizedName,
                        tint: subscription.category.tintColor
                    )

                    if subscription.status == .paused {
                        PillBadge(
                            text: String(
                                localized: "subscriptions.status.paused",
                                defaultValue: "Pausada"
                            ),
                            tint: .appAmber
                        )
                    }
                }
            }

            Spacer(minLength: AppSpacing.s)

            VStack(alignment: .trailing, spacing: 4) {
                CurrencyText(
                    amount: subscription.amount,
                    currencyCode: subscription.currencyCode,
                    font: .headline
                )

                Text(subscription.frequency.localizedName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .glassCard()
    }
}

// MARK: - Vista previa

#Preview {
    SubscriptionListView()
        .environment(\.dependencies, AppDependencies.preview())
}
