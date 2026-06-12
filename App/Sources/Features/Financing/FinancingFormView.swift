//
//  FinancingFormView.swift
//  Subscription Guardian
//
//  Formulario de alta y edición de financiaciones BNPL.
//

import SwiftUI
import SubscriptionGuardianCore

/// Modo del formulario de financiación.
enum FinancingFormMode {
    case create
    case edit(Financing)
}

struct FinancingFormView: View {
    @Environment(\.dependencies) private var deps
    @Environment(\.dismiss) private var dismiss

    private let mode: FinancingFormMode

    // Estado del formulario.
    @State private var merchant = ""
    @State private var provider: BNPLProvider = .custom
    @State private var totalAmountText = ""
    @State private var monthlyAmountText = ""
    @State private var interestText = ""
    /// Número de cuotas como texto: admite teclado numérico y botones +/−.
    @State private var installmentsText = "12"
    @State private var hasFirstInstallmentDate = true
    @State private var firstInstallmentDate = Date()
    @State private var notes = ""

    @State private var showPaywall = false
    @State private var errorMessage: String?

    init(mode: FinancingFormMode) {
        self.mode = mode
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var totalAmount: Decimal? {
        Decimal(string: totalAmountText.replacingOccurrences(of: ",", with: "."))
    }

    private var monthlyAmount: Decimal? {
        Decimal(string: monthlyAmountText.replacingOccurrences(of: ",", with: "."))
    }

    /// Número de cuotas parseado del texto, acotado a un rango razonable.
    private var totalInstallments: Int {
        min(120, max(0, Int(installmentsText) ?? 0))
    }

    /// Cuotas ya devengadas según la fecha de la primera cuota; se marcarán
    /// como pagadas automáticamente al guardar.
    private var accruedInstallments: Int {
        guard hasFirstInstallmentDate, totalInstallments > 0 else { return 0 }
        return FinancingCalculator.accruedInstallments(
            firstInstallmentDate: firstInstallmentDate,
            totalInstallments: totalInstallments
        )
    }

    private var isValid: Bool {
        !merchant.trimmingCharacters(in: .whitespaces).isEmpty
            && (totalAmount ?? 0) > 0
            && (monthlyAmount ?? 0) > 0
            && totalInstallments >= 1
    }

    /// Fecha estimada de la última cuota, derivada de los campos actuales.
    private var lastInstallmentDate: Date? {
        guard hasFirstInstallmentDate else { return nil }
        return Calendar.current.date(
            byAdding: .month,
            value: max(0, totalInstallments - 1),
            to: firstInstallmentDate
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "financing.form.merchantSection", defaultValue: "Comercio")) {
                    FloatingField(
                        label: String(localized: "financing.form.merchant", defaultValue: "Nombre del comercio")
                    ) {
                        TextField("Apple Store", text: $merchant)
                    }
                    Picker(
                        String(localized: "financing.form.provider", defaultValue: "Proveedor"),
                        selection: $provider
                    ) {
                        ForEach(BNPLProvider.allCases, id: \.self) { provider in
                            Text(provider.localizedName).tag(provider)
                        }
                    }
                }

                Section(String(localized: "financing.form.amountsSection", defaultValue: "Importes")) {
                    FloatingField(
                        label: String(localized: "financing.form.totalAmount", defaultValue: "Importe total")
                    ) {
                        TextField("1.248,00", text: $totalAmountText)
                            .keyboardType(.decimalPad)
                    }

                    installmentsRow

                    HStack(alignment: .bottom) {
                        FloatingField(
                            label: String(localized: "financing.form.monthlyAmount", defaultValue: "Cuota mensual")
                        ) {
                            TextField("104,00", text: $monthlyAmountText)
                                .keyboardType(.decimalPad)
                        }

                        // Cálculo de cuota: debe sentirse inteligente y vivo.
                        Button {
                            withAnimation(AppMotion.standard) {
                                suggestMonthlyAmount()
                            }
                        } label: {
                            Label(
                                String(localized: "financing.form.calculate", defaultValue: "Calcular"),
                                systemImage: "wand.and.stars"
                            )
                            .font(.caption.bold())
                            .foregroundStyle((totalAmount ?? 0) > 0 ? Color.appCyan : Color.secondary)
                        }
                        .disabled((totalAmount ?? 0) <= 0)
                    }

                    FloatingField(
                        label: String(localized: "financing.form.interest", defaultValue: "Interés % (opcional)")
                    ) {
                        TextField("0,0", text: $interestText)
                            .keyboardType(.decimalPad)
                    }
                }

                Section {
                    Toggle(
                        String(localized: "financing.form.hasFirstDate", defaultValue: "Fecha de primera cuota"),
                        isOn: $hasFirstInstallmentDate.animation(AppMotion.standard)
                    )
                    .tint(.appTeal)
                    if hasFirstInstallmentDate {
                        DatePicker(
                            String(localized: "financing.form.firstDate", defaultValue: "Primera cuota"),
                            selection: $firstInstallmentDate,
                            displayedComponents: .date
                        )
                        if let lastInstallmentDate {
                            LabeledContent(
                                String(localized: "financing.form.lastDate", defaultValue: "Última cuota")
                            ) {
                                Text(lastInstallmentDate, format: .dateTime.day().month(.abbreviated).year())
                            }
                        }
                        if accruedInstallments > 0 {
                            // Insight contextual con jerarquía propia, no una
                            // fila secundaria más.
                            HStack(spacing: AppSpacing.s) {
                                Image(systemName: "sparkles")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(Color.appCyan)

                                Text(
                                    String(
                                        localized: "financing.form.accrued",
                                        defaultValue: "Cuotas ya devengadas"
                                    )
                                )
                                .font(.footnote.weight(.medium))

                                Spacer()

                                Text(
                                    String(
                                        localized: "financing.form.accruedValue",
                                        defaultValue: "\(accruedInstallments) de \(totalInstallments)"
                                    )
                                )
                                .font(.system(.footnote, design: .rounded).bold())
                                .foregroundStyle(Color.appCyan)
                            }
                            .padding(.vertical, AppSpacing.xxs)
                            .listRowBackground(Color.appCyan.opacity(0.08))
                        }
                    }
                } header: {
                    Text("financing.form.datesSection", comment: "Fechas")
                } footer: {
                    if hasFirstInstallmentDate {
                        Text(
                            "financing.form.accruedFooter",
                            comment: "Las cuotas con vencimiento anterior o igual a hoy se marcan automáticamente como pagadas."
                        )
                    }
                }

                Section(String(localized: "common.notes", defaultValue: "Notas")) {
                    TextField(
                        String(localized: "financing.form.notesPlaceholder", defaultValue: "Observaciones"),
                        text: $notes,
                        axis: .vertical
                    )
                    .lineLimit(2...5)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .appBackground()
            .navigationTitle(
                isEditing
                    ? Text("financing.form.editTitle", comment: "Editar financiación")
                    : Text("financing.form.createTitle", comment: "Nueva financiación")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel", defaultValue: "Cancelar")) {
                        dismiss()
                    }
                }
            }
            // CTA hero de cierre de flujo: flotante y claramente prioritario.
            .safeAreaInset(edge: .bottom) {
                Button {
                    save()
                } label: {
                    Label(
                        String(localized: "financing.form.savePlan", defaultValue: "Guardar plan"),
                        systemImage: "checkmark.seal.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primaryMagenta)
                .disabled(!isValid)
                .opacity(isValid ? 1 : 0.5)
                .padding(.horizontal, AppSpacing.l)
                .padding(.vertical, AppSpacing.s)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .onAppear(perform: populateFromMode)
        }
    }

    // MARK: - Componentes

    /// Stepper premium del número de cuotas: campo excavado con teclado
    /// numérico y botones +/− con presencia y feedback táctil.
    private var installmentsRow: some View {
        HStack {
            Text("financing.form.installmentsLabel", comment: "Número de cuotas")

            Spacer()

            Button {
                withAnimation(AppMotion.tap) { adjustInstallments(by: -1) }
            } label: {
                Image(systemName: "minus")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(totalInstallments > 1 ? Color.appCyan : Color.secondary)
                    .frame(width: 32, height: 32)
                    .insetPanel(cornerRadius: AppRadius.small, padding: 0)
            }
            .buttonStyle(.pressableCard)
            .disabled(totalInstallments <= 1)
            .accessibilityLabel(
                String(localized: "financing.form.fewerInstallments", defaultValue: "Quitar una cuota")
            )

            TextField("12", text: $installmentsText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(.body, design: .rounded).bold())
                .frame(width: 56)
                .padding(.vertical, 4)
                .insetPanel(cornerRadius: AppRadius.small, padding: 0)
                .contentTransition(.numericText())

            Button {
                withAnimation(AppMotion.tap) { adjustInstallments(by: 1) }
            } label: {
                Image(systemName: "plus")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.appCyan)
                    .frame(width: 32, height: 32)
                    .insetPanel(cornerRadius: AppRadius.small, padding: 0)
            }
            .buttonStyle(.pressableCard)
            .accessibilityLabel(
                String(localized: "financing.form.moreInstallments", defaultValue: "Añadir una cuota")
            )
        }
    }

    // MARK: - Acciones

    /// Ajusta el número de cuotas desde los botones +/− manteniendo el texto.
    private func adjustInstallments(by delta: Int) {
        let current = Int(installmentsText) ?? 0
        installmentsText = "\(min(120, max(1, current + delta)))"
    }

    /// Sugerencia de cuota: importe total dividido entre el número de cuotas.
    private func suggestMonthlyAmount() {
        guard let total = totalAmount, totalInstallments > 0 else { return }
        let suggested = Money.rounded(Money.divide(total, by: Decimal(totalInstallments)))
        monthlyAmountText = "\(suggested)"
    }

    private func populateFromMode() {
        guard case .edit(let financing) = mode else { return }
        merchant = financing.merchant
        provider = financing.provider
        totalAmountText = "\(financing.totalAmount)"
        monthlyAmountText = "\(financing.monthlyAmount)"
        interestText = financing.interestRate == 0 ? "" : "\(financing.interestRate)"
        installmentsText = "\(financing.totalInstallments)"
        hasFirstInstallmentDate = financing.firstInstallmentDate != nil
        firstInstallmentDate = financing.firstInstallmentDate ?? Date()
        notes = financing.notes
    }

    private func save() {
        guard let deps, let totalAmount, let monthlyAmount else { return }

        var draft = FinancingDraft()
        draft.merchant = merchant.trimmingCharacters(in: .whitespaces)
        draft.provider = provider
        draft.totalAmount = totalAmount
        draft.monthlyAmount = monthlyAmount
        draft.interestRate = Decimal(string: interestText.replacingOccurrences(of: ",", with: ".")) ?? 0
        draft.totalInstallments = totalInstallments
        draft.firstInstallmentDate = hasFirstInstallmentDate ? firstInstallmentDate : nil
        draft.notes = notes

        do {
            switch mode {
            case .create:
                _ = try deps.financings.create(from: draft)
            case .edit(let financing):
                try deps.financings.update(financing, with: draft)
            }
            dismiss()
        } catch RepositoryError.freeTierLimitReached {
            showPaywall = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    FinancingFormView(mode: .create)
        .environment(\.dependencies, AppDependencies.preview())
}
