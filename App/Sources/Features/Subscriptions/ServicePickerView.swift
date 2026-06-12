//
//  ServicePickerView.swift
//  Subscription Guardian
//
//  Galería de servicios populares: cuadrícula editorial, rápida de escanear
//  y agradable de tocar. El servicio personalizado es una alternativa
//  valiosa, no un fallback.
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
                        .buttonStyle(.pressableCard)
                    }
                }
                .padding(AppSpacing.m)

                // Alternativa valiosa: crear un servicio desde cero.
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: AppSpacing.m) {
                        ZStack {
                            RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                                .fill(LinearGradient.appAccent)
                                .frame(width: 40, height: 40)
                            Image(systemName: "plus")
                                .font(.body.weight(.bold))
                                .foregroundStyle(.white)
                        }
                        .glow(.appCyan, radius: 8, opacity: 0.35)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(
                                localized: "subscriptions.picker.custom",
                                defaultValue: "Servicio personalizado"
                            ))
                            .font(.subheadline.weight(.semibold))
                            Text(String(
                                localized: "subscriptions.picker.customHint",
                                defaultValue: "Crea cualquier servicio a tu medida"
                            ))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .glassCard(cornerRadius: AppRadius.medium, padding: AppSpacing.sm)
                }
                .buttonStyle(.pressableCard)
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

    /// Ficha premium de marca: logo con glow temático, no solo texto.
    private func templateCell(_ template: ServiceTemplate) -> some View {
        VStack(spacing: AppSpacing.s) {
            BrandIconView(
                symbol: template.symbol,
                monogram: template.monogram,
                colorHex: template.colorHex,
                size: 54
            )
            .glow(Color(hex: template.colorHex), radius: 12, opacity: 0.35)

            Text(template.name)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxs)
        .glassCard(cornerRadius: AppRadius.medium, padding: AppSpacing.s)
    }
}

// MARK: - Vista previa

#Preview {
    ServicePickerView { _ in }
}
