//
//  PrimaryButtonStyle.swift
//  Subscription Guardian
//
//  Estilo de botón principal: cápsula con gradiente de acento y efecto de pulsación.
//

import SwiftUI

/// Estilo de botón principal de la app con gradiente y animación al pulsar.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, AppSpacing.l)
            .frame(minHeight: 50)
            .background(LinearGradient.appAccent, in: Capsule())
            // Sombra teñida con el azul de acento para dar sensación de elevación.
            .shadow(color: Color.electricBlue.opacity(0.35), radius: 12, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(
                .spring(response: 0.3, dampingFraction: 0.7),
                value: configuration.isPressed
            )
    }
}

// MARK: - Acceso abreviado

extension ButtonStyle where Self == PrimaryButtonStyle {
    /// Permite escribir `.buttonStyle(.primary)`.
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

// MARK: - Vista previa

#Preview {
    ZStack {
        AppBackground()

        VStack(spacing: AppSpacing.m) {
            Button("Add subscription") {}
                .buttonStyle(.primary)

            Button {
            } label: {
                Label("Scan inbox", systemImage: "envelope.badge")
            }
            .buttonStyle(.primary)
        }
        .padding(AppSpacing.l)
    }
}
