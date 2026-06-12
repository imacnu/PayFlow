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
    @State private var totalInstallments = 12
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
                    TextField(
                        String(localized: "financing.form.merchant", defaultValue: "Nombre del comercio"),
                        text: $merchant
                    )
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
                    TextField(
                        String(localized: "financing.form.totalAmount", defaultValue: "Importe total"),
                        text: $totalAmountText
                    )
                    .keyboardType(.decimalPad)

                    Stepper(value: $totalInstallments, in: 1...60) {
                        Text(
                            String(
                                localized: "financing.form.installments",
                                defaultValue: "\(totalInstallments) cuotas"
                            )
                        )
                    }

                    HStack {
                        TextField(
                            String(localized: "financing.form.monthlyAmount", defaultValue: "Cuota mensual"),
                            text: $monthlyAmountText
                        )
                        .keyboardType(.decimalPad)

                        Button(String(localized: "financing.form.calculate", defaultValue: "Calcular")) {
                            suggestMonthlyAmount()
                        }
                        .font(.caption.bold())
                        .disabled((totalAmount ?? 0) <= 0)
                    }

                    TextField(
                        String(localized: "financing.form.interest", defaultValue: "Interés % (opcional)"),
                        text: $interestText
                    )
                    .keyboardType(.decimalPad)
                }

                Section(String(localized: "financing.form.datesSection", defaultValue: "Fechas")) {
                    Toggle(
                        String(localized: "financing.form.hasFirstDate", defaultValue: "Fecha de primera cuota"),
                        isOn: $hasFirstInstallmentDate
                    )
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
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.save", defaultValue: "Guardar")) {
                        save()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .onAppear(perform: populateFromMode)
        }
    }

    // MARK: - Acciones

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
        totalInstallments = financing.totalInstallments
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
