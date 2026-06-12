//
//  FinancingDetailView.swift
//  Subscription Guardian
//
//  Detalle de una financiación: progreso, indicadores clave y acciones
//  sobre las cuotas.
//

import SwiftUI
import SubscriptionGuardianCore

struct FinancingDetailView: View {
    @Environment(\.dependencies) private var deps
    @Environment(\.dismiss) private var dismiss

    let financing: Financing

    @State private var showEditForm = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.m) {
                header
                progressSection
                kpiSection
                actionsSection
                if !financing.notes.isEmpty {
                    notesSection
                }
            }
            .padding(.horizontal, AppSpacing.m)
            .padding(.bottom, AppSpacing.xl)
        }
        .appBackground()
        .navigationTitle(financing.merchant)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(String(localized: "common.edit", defaultValue: "Editar")) {
                    showEditForm = true
                }
            }
        }
        .sheet(isPresented: $showEditForm) {
            FinancingFormView(mode: .edit(financing))
        }
        .confirmationDialog(
            String(
                localized: "financing.delete.confirm",
                defaultValue: "¿Eliminar esta financiación?"
            ),
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                String(localized: "common.delete", defaultValue: "Eliminar"),
                role: .destructive
            ) {
                try? deps?.financings.delete(financing)
                dismiss()
            }
        }
    }

    // MARK: - Secciones

    private var header: some View {
        GlassCard {
            VStack(spacing: AppSpacing.s) {
                Text(financing.merchant)
                    .font(.title2.bold())

                HStack(spacing: AppSpacing.s) {
                    PillBadge(text: financing.provider.localizedName, tint: .electricBlue)
                    if financing.status == .completed {
                        PillBadge(
                            text: String(localized: "financing.status.completed", defaultValue: "Completada"),
                            tint: .green
                        )
                    } else if financing.status == .cancelled {
                        PillBadge(
                            text: String(localized: "financing.status.cancelled", defaultValue: "Cancelada"),
                            tint: .gray
                        )
                    } else {
                        PillBadge(
                            text: String(localized: "financing.status.active", defaultValue: "Activa"),
                            tint: .appCyan
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var progressSection: some View {
        GlassCard {
            VStack(spacing: AppSpacing.m) {
                if financing.status == .completed {
                    // Estado de celebración al terminar todas las cuotas.
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.green)
                    Text("financing.detail.completedMessage", comment: "Mensaje de financiación completada")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                } else {
                    ZStack {
                        ProgressRing(progress: financing.progress, lineWidth: 10, size: 120)
                        VStack(spacing: 2) {
                            Text("\(Int((financing.progress * 100).rounded()))%")
                                .font(.title3.bold())
                                .contentTransition(.numericText())
                            Text("financing.detail.paid", comment: "pagado")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Text(
                    String(
                        localized: "financing.row.progress",
                        defaultValue: "\(financing.paidInstallments) de \(financing.totalInstallments) cuotas pagadas"
                    )
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var kpiSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.m) {
            kpiCell(
                title: String(localized: "financing.detail.monthlyAmount", defaultValue: "Cuota mensual"),
                amount: financing.monthlyAmount
            )
            kpiCell(
                title: String(localized: "financing.summary.pendingCapital", defaultValue: "Capital pendiente"),
                amount: financing.pendingCapital
            )
            kpiDateCell(
                title: String(localized: "financing.detail.nextPayment", defaultValue: "Próximo pago"),
                date: financing.nextInstallmentDate
            )
            kpiDateCell(
                title: String(localized: "financing.detail.endDate", defaultValue: "Finalización"),
                date: financing.endDate
            )
        }
    }

    private func kpiCell(title: String, amount: Decimal) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            CurrencyText(amount: amount, currencyCode: "EUR", font: .title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func kpiDateCell(title: String, date: Date?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let date {
                Text(date, format: .dateTime.day().month(.abbreviated).year())
                    .font(.title3.bold())
            } else {
                Text("common.notAvailable", comment: "No disponible")
                    .font(.title3.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private var actionsSection: some View {
        VStack(spacing: AppSpacing.s) {
            if financing.status != .completed {
                Button {
                    withAnimation(.spring) {
                        try? deps?.financings.markInstallmentPaid(financing)
                    }
                } label: {
                    Label(
                        String(localized: "financing.detail.markPaid", defaultValue: "Marcar cuota pagada"),
                        systemImage: "checkmark.circle.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary)
            }

            if financing.paidInstallments > 0 {
                Button {
                    withAnimation(.spring) {
                        try? deps?.financings.undoInstallment(financing)
                    }
                } label: {
                    Label(
                        String(localized: "financing.detail.undoPaid", defaultValue: "Deshacer última cuota"),
                        systemImage: "arrow.uturn.backward"
                    )
                }
                .font(.subheadline)
            }

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Text("common.delete", comment: "Eliminar")
            }
            .font(.subheadline)
        }
        .padding(.top, AppSpacing.s)
    }

    private var notesSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 4) {
                Text("common.notes", comment: "Notas")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(financing.notes)
                    .font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
