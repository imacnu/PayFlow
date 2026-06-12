//
//  FloatingField.swift
//  Subscription Guardian
//
//  Campo de formulario con label flotante: etiqueta en mayúsculas, cian y
//  con tracking amplio sobre el valor, como en los form-cards del mockup.
//

import SwiftUI

/// Envuelve cualquier control con la etiqueta flotante del sistema de diseño.
struct FloatingField<Content: View>: View {
    let label: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .kerning(1.3)
                .foregroundStyle(Color.appCyan)

            content
                .font(.system(size: 17))
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Vista previa

#Preview {
    ZStack {
        AppBackground()

        VStack(alignment: .leading, spacing: AppSpacing.m) {
            FloatingField(label: "Nombre") {
                TextField("Netflix Premium", text: .constant(""))
            }
            FloatingField(label: "Precio") {
                TextField("12,00 €", text: .constant("12,00"))
            }
        }
        .glassCard()
        .padding(AppSpacing.l)
    }
    .preferredColorScheme(.dark)
}
