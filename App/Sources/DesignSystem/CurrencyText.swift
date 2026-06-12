//
//  CurrencyText.swift
//  Subscription Guardian
//
//  Texto de importe monetario con formato de moneda y transición numérica.
//

import SwiftUI

/// Muestra un importe con formato de moneda localizado y transición numérica.
struct CurrencyText: View {
    let amount: Decimal
    /// Código ISO 4217, p. ej. "USD" o "EUR".
    let currencyCode: String
    /// Los valores financieros son el punto de mayor protagonismo
    /// tipográfico: peso 800, dígitos tabulares y transición numérica.
    var font: Font = .system(size: 30, weight: .heavy).monospacedDigit()

    var body: some View {
        Text(amount, format: .currency(code: currencyCode))
            .font(font)
            .contentTransition(.numericText())
    }
}

// MARK: - Vista previa

#Preview {
    ZStack {
        AppBackground()

        VStack(spacing: AppSpacing.m) {
            CurrencyText(amount: 42.97, currencyCode: "USD")
            CurrencyText(amount: 9.99, currencyCode: "EUR", font: .headline)
            CurrencyText(amount: 1299, currencyCode: "JPY", font: .largeTitle.bold())
        }
        .glassCard()
        .padding(AppSpacing.l)
    }
}
