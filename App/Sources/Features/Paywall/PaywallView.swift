import SwiftUI
import StoreKit

/// Pantalla de pago de Subscription Guardian Premium.
/// Se presenta como hoja desde varios puntos de la app.
struct PaywallView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = PaywallViewModel()
    /// Se activa tras una compra completada para mostrar el estado de éxito.
    @State private var purchaseSucceeded = false

    /// Estado de éxito: compra recién completada o usuario ya premium.
    private var showsSuccess: Bool {
        purchaseSucceeded || viewModel.isPremium
    }

    var body: some View {
        NavigationStack {
            Group {
                if showsSuccess {
                    successContent
                } else {
                    paywallContent
                }
            }
            .appBackground()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(
                        String(localized: "common.close", defaultValue: "Cerrar")
                    )
                }
            }
        }
        .task {
            viewModel.configure(deps: dependencies)
            await viewModel.load()
        }
    }

    // MARK: - Contenido principal

    private var paywallContent: some View {
        ScrollView {
            VStack(spacing: AppSpacing.l) {
                hero
                benefits
                productCards
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
                ctaButton
                restoreButton
                legalFooter
            }
            .padding(AppSpacing.l)
        }
    }

    /// Cabecera con la corona sobre círculo de gradiente.
    private var hero: some View {
        VStack(spacing: AppSpacing.m) {
            ZStack {
                Circle()
                    .fill(LinearGradient.appAccent)
                    .frame(width: 88, height: 88)
                    .shadow(color: Color.appCyan.opacity(0.3), radius: 16, x: 0, y: 8)

                Image(systemName: "crown.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text(verbatim: "Subscription Guardian Premium")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
        }
    }

    /// Lista de ventajas del plan premium.
    private var benefits: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.m) {
                benefitRow(String(
                    localized: "paywall.benefit.unlimited",
                    defaultValue: "Suscripciones y financiaciones ilimitadas"
                ))
                benefitRow(String(
                    localized: "paywall.benefit.widgets",
                    defaultValue: "Widgets avanzados"
                ))
                benefitRow(String(
                    localized: "paywall.benefit.insights",
                    defaultValue: "Insights inteligentes"
                ))
                benefitRow(String(
                    localized: "paywall.benefit.export",
                    defaultValue: "Exportación CSV"
                ))
                benefitRow(String(
                    localized: "paywall.benefit.backup",
                    defaultValue: "Copia de seguridad avanzada"
                ))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Fila individual de ventaja con marca de verificación.
    private func benefitRow(_ text: String) -> some View {
        HStack(spacing: AppSpacing.s) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.appCyan)
            Text(text)
                .font(.subheadline)
        }
    }

    /// Tarjetas de producto o aviso si no hay productos disponibles.
    @ViewBuilder
    private var productCards: some View {
        if viewModel.products.isEmpty {
            GlassCard {
                VStack(spacing: AppSpacing.s) {
                    Text(String(
                        localized: "paywall.products.empty.title",
                        defaultValue: "Productos no disponibles"
                    ))
                    .font(.headline)

                    Text(String(
                        localized: "paywall.products.empty.message",
                        defaultValue: "No se han podido cargar los planes. Comprueba tu conexión o inténtalo más tarde."
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        } else {
            VStack(spacing: AppSpacing.m) {
                ForEach(viewModel.products, id: \.id) { product in
                    productCard(product)
                }
            }
        }
    }

    /// Tarjeta seleccionable de un producto de StoreKit.
    private func productCard(_ product: Product) -> some View {
        let isSelected = viewModel.selectedProduct?.id == product.id
        let isYearly = product.id == AppConfig.yearlyProductID

        return Button {
            viewModel.selectedProduct = product
        } label: {
            HStack(spacing: AppSpacing.m) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: AppSpacing.s) {
                        Text(product.displayName)
                            .font(.headline)
                        if isYearly {
                            PillBadge(
                                text: String(
                                    localized: "paywall.badge.save",
                                    defaultValue: "Ahorra un 30%"
                                ),
                                tint: .appCyan
                            )
                        }
                    }
                    Text(periodCaption(for: product))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Text(product.displayPrice)
                    .font(.title3.bold())
            }
            .frame(maxWidth: .infinity)
            .glassCard()
            // Resalte de la tarjeta seleccionada con trazo de acento.
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.appCyan : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }

    /// Texto del periodo de facturación según el identificador del producto.
    private func periodCaption(for product: Product) -> String {
        if product.id == AppConfig.yearlyProductID {
            return String(localized: "paywall.period.year", defaultValue: "al año")
        }
        return String(localized: "paywall.period.month", defaultValue: "al mes")
    }

    /// Botón principal de compra.
    private var ctaButton: some View {
        Button {
            Task {
                if await viewModel.purchase() {
                    purchaseSucceeded = true
                }
            }
        } label: {
            Text(String(localized: "paywall.cta", defaultValue: "Continuar"))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.primary)
        .disabled(viewModel.selectedProduct == nil || viewModel.purchaseInProgress)
    }

    /// Botón de texto para restaurar compras anteriores.
    private var restoreButton: some View {
        Button(String(localized: "paywall.restore", defaultValue: "Restaurar compras")) {
            Task { await viewModel.restore() }
        }
        .font(.subheadline)
        .disabled(viewModel.purchaseInProgress)
    }

    /// Nota legal al pie de la pantalla.
    private var legalFooter: some View {
        Text(String(
            localized: "paywall.legal",
            defaultValue: "La suscripción se renueva automáticamente hasta que se cancele en los ajustes de la App Store. El pago se carga a tu cuenta de Apple al confirmar la compra."
        ))
        .font(.caption2)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }

    // MARK: - Estado de éxito

    /// Estado de éxito tras la compra: se cierra solo tras una breve pausa.
    private var successContent: some View {
        VStack(spacing: AppSpacing.m) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(.green)

            Text(String(localized: "paywall.success.title", defaultValue: "¡Ya eres Premium!"))
                .font(.title2.bold())

            Text(String(
                localized: "paywall.success.message",
                defaultValue: "Disfruta de todas las funciones sin límites."
            ))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding(AppSpacing.l)
        .task {
            // Pausa breve para que el usuario vea la confirmación.
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            dismiss()
        }
    }
}

// MARK: - Vista previa

#Preview {
    PaywallView()
        .environment(\.dependencies, AppDependencies.preview())
}
