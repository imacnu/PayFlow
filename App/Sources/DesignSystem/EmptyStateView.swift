//
//  EmptyStateView.swift
//  Subscription Guardian
//
//  Vista de estado vacío con icono destacado, mensaje y acción opcional.
//

import SwiftUI

/// Estado vacío centrado: icono grande sobre círculo con gradiente,
/// título, mensaje y un botón de acción opcional.
struct EmptyStateView: View {
    /// Nombre de un SF Symbol.
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppSpacing.m) {
            // Símbolo grande dentro de un círculo con el gradiente de acento.
            ZStack {
                Circle()
                    .fill(LinearGradient.appAccent)
                    .frame(width: 88, height: 88)
                    .shadow(color: Color.electricBlue.opacity(0.3), radius: 16, x: 0, y: 8)

                Image(systemName: icon)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: AppSpacing.s) {
                Text(title)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Botón de acción opcional con el estilo principal.
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.primary)
                    .padding(.top, AppSpacing.s)
            }
        }
        .padding(AppSpacing.l)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Vista previa

#Preview {
    ZStack {
        AppBackground()

        EmptyStateView(
            icon: "creditcard",
            title: "No subscriptions yet",
            message: "Add your first subscription to start tracking your monthly spending.",
            actionTitle: "Add subscription",
            action: {}
        )
        .padding(AppSpacing.l)
    }
}
