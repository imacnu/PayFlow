//
//  SubscriptionFormView.swift
//  Subscription Guardian
//
//  Formulario de alta y edición de suscripciones, presentado como hoja.
//

import SwiftUI
import SubscriptionGuardianCore

/// Formulario de suscripción (alta o edición) dentro de una hoja.
struct SubscriptionFormView: View {
    @Environment(\.dependencies) private var deps
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: SubscriptionFormViewModel
    @State private var showServicePicker = false

    init(mode: SubscriptionFormMode) {
        _viewModel = State(initialValue: SubscriptionFormViewModel(mode: mode))
    }

    var body: some View {
        NavigationStack {
            Form {
                if !viewModel.isEditing {
                    quickPickSection
                }
                dataSection
                renewalSection
                appearanceSection
                notesSection

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .appBackground()
            .navigationTitle(formTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel", defaultValue: "Cancelar")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.save", defaultValue: "Guardar")) {
                        if viewModel.save() {
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.isValid)
                }
            }
            .sheet(isPresented: $showServicePicker) {
                ServicePickerView { template in
                    viewModel.apply(template: template)
                }
            }
            .sheet(isPresented: $viewModel.showPaywall) {
                PaywallView()
            }
            .task {
                viewModel.configure(deps: deps)
            }
        }
    }

    // MARK: - Secciones

    /// Acceso rápido al catálogo de servicios conocidos.
    private var quickPickSection: some View {
        Section {
            Button {
                showServicePicker = true
            } label: {
                HStack(spacing: AppSpacing.m) {
                    BrandIconView(
                        symbol: viewModel.iconSymbol,
                        monogram: viewModel.monogram,
                        colorHex: viewModel.colorHex,
                        size: 36
                    )
                    Text(String(
                        localized: "subscriptions.form.catalog",
                        defaultValue: "Elegir de servicios populares"
                    ))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    /// Datos principales: nombre, categoría, precio, divisa y frecuencia.
    private var dataSection: some View {
        Section(String(
            localized: "subscriptions.form.section.data",
            defaultValue: "Datos del servicio"
        )) {
            TextField(
                String(localized: "subscriptions.form.name", defaultValue: "Nombre"),
                text: $viewModel.name
            )

            Picker(
                String(localized: "subscriptions.form.category", defaultValue: "Categoría"),
                selection: $viewModel.category
            ) {
                ForEach(ServiceCategory.allCases, id: \.self) { category in
                    Text(category.localizedName).tag(category)
                }
            }

            TextField(
                String(localized: "subscriptions.form.price", defaultValue: "Precio"),
                text: $viewModel.amountText
            )
            .keyboardType(.decimalPad)

            Picker(
                String(localized: "subscriptions.form.currency", defaultValue: "Moneda"),
                selection: $viewModel.currencyCode
            ) {
                ForEach(SubscriptionFormViewModel.currencyOptions, id: \.self) { code in
                    Text(code).tag(code)
                }
            }

            Picker(
                String(localized: "subscriptions.form.frequency", defaultValue: "Frecuencia"),
                selection: $viewModel.frequency
            ) {
                ForEach(BillingFrequency.allCases, id: \.self) { frequency in
                    Text(frequency.localizedName).tag(frequency)
                }
            }
        }
    }

    /// Renovación y recordatorio.
    private var renewalSection: some View {
        Section(String(
            localized: "subscriptions.form.section.renewal",
            defaultValue: "Renovación"
        )) {
            Toggle(
                String(
                    localized: "subscriptions.form.hasrenewal",
                    defaultValue: "Tiene fecha de renovación"
                ),
                isOn: $viewModel.hasRenewalDate
            )

            if viewModel.hasRenewalDate {
                DatePicker(
                    String(
                        localized: "subscriptions.form.renewaldate",
                        defaultValue: "Próxima renovación"
                    ),
                    selection: $viewModel.renewalDate,
                    displayedComponents: .date
                )
            }

            Picker(
                String(
                    localized: "subscriptions.form.reminder",
                    defaultValue: "Recordatorio"
                ),
                selection: $viewModel.reminderDaysBefore
            ) {
                ForEach(SubscriptionFormViewModel.reminderOptions, id: \.self) { days in
                    Text(String(
                        localized: "subscriptions.form.reminder.option",
                        defaultValue: "\(days) días antes"
                    ))
                    .tag(days)
                }
            }
        }
    }

    /// Selección de icono y color de marca.
    private var appearanceSection: some View {
        Section(String(
            localized: "subscriptions.form.section.appearance",
            defaultValue: "Icono y color"
        )) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: AppSpacing.s) {
                ForEach(SubscriptionFormViewModel.symbolOptions, id: \.self) { symbol in
                    Button {
                        viewModel.iconSymbol = symbol
                    } label: {
                        Image(systemName: symbol)
                            .font(.body.weight(.semibold))
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                                    .fill(viewModel.iconSymbol == symbol
                                          ? Color.electricBlue.opacity(0.2)
                                          : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                                    .strokeBorder(
                                        viewModel.iconSymbol == symbol ? Color.electricBlue : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: AppSpacing.s) {
                ForEach(SubscriptionFormViewModel.colorOptions, id: \.self) { hex in
                    Button {
                        viewModel.colorHex = hex
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 36, height: 36)
                            if viewModel.colorHex == hex {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    /// Notas libres.
    private var notesSection: some View {
        Section(String(
            localized: "subscriptions.form.section.notes",
            defaultValue: "Notas"
        )) {
            TextField(
                String(localized: "subscriptions.form.notes", defaultValue: "Notas"),
                text: $viewModel.notes,
                axis: .vertical
            )
            .lineLimit(3...6)
        }
    }

    // MARK: - Valores derivados

    private var formTitle: String {
        if viewModel.isEditing {
            return String(
                localized: "subscriptions.form.title.edit",
                defaultValue: "Editar suscripción"
            )
        }
        return String(
            localized: "subscriptions.form.title.create",
            defaultValue: "Nueva suscripción"
        )
    }
}
