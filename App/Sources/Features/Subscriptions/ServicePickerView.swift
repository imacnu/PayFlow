//
//  ServicePickerView.swift
//  Subscription Guardian
//
//  Selector de servicios populares del catálogo para el alta rápida.
//

import SwiftUI
import SubscriptionGuardianCore

/// Cuadrícula de plantillas de servicios conocidos. Al tocar una se invoca
/// `onSelect` y se cierra la hoja.
struct ServicePickerView: View {
    @Environment(\.dismiss) private var dismiss

    /// Callback con la plantilla elegida.
    let onSelect: (ServiceTemplate) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.m), count: 3)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: AppSpacing.m) {
                    ForEach(ServiceCatalog.all) { template in
                        Button {
                            onSelect(template)
                            dismiss()
                        } label: {
                            templateCell(template)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(AppSpacing.m)

                // Opción para crear un servicio desde cero.
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: AppSpacing.s) {
                        Image(systemName: "plus.circle.fill")
                        Text(String(
                            localized: "subscriptions.picker.custom",
                            defaultValue: "Servicio personalizado"
                        ))
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 24)
                }
                .glassCard(cornerRadius: AppRadius.control, padding: 12)
                .padding(.horizontal, AppSpacing.m)
                .padding(.bottom, AppSpacing.l)
            }
            .appBackground()
            .navigationTitle(String(
                localized: "subscriptions.picker.title",
                defaultValue: "Servicios populares"
            ))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel", defaultValue: "Cancelar")) {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Celdas

    private func templateCell(_ template: ServiceTemplate) -> some View {
        VStack(spacing: AppSpacing.s) {
            BrandIconView(
                symbol: template.symbol,
                monogram: template.monogram,
                colorHex: template.colorHex,
                size: 48
            )

            Text(template.name)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if let price = template.suggestedMonthlyPrice {
                Text(price, format: .currency(code: "EUR"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: AppRadius.control, padding: AppSpacing.s)
    }
}

// MARK: - Vista previa

#Preview {
    ServicePickerView { _ in }
}
