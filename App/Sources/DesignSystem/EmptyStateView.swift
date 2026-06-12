//
//  EmptyStateView.swift
//  Subscription Guardian
//
//  Estado vacío hero: composición central con glow y flotación sutil,
//  copy inspirador y CTA principal. El vacío también diseña percepción.
//

import SwiftUI

/// Estado vacío centrado: icono grande flotando sobre un halo de luz,
/// título, mensaje y un botón de acción opcional con estilo hero.
struct EmptyStateView: View {
    /// Nombre de un SF Symbol.
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    /// Icono opcional del CTA (las acciones críticas llevan icono).
    var actionIcon: String? = nil
    var action: (() -> Void)? = nil

    /// Fase de la flotación sutil del icono.
    @State private var floating = false

    var body: some View {
        VStack(spacing: AppSpacing.m) {
            // Composición hero: halo difuminado + cápsula con gradiente
            // y flotación lenta que da vida al vacío.
            ZStack {
                // Halo de luz ambiental detrás del icono.
                Circle()
                    .fill(Color.appCyan.opacity(0.25))
                    .frame(width: 140, height: 140)
                    .blur(radius: 40)

                Circle()
                    .fill(LinearGradient.appAccent)
                    .frame(width: 92, height: 92)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.55), Color.white.opacity(0.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                    .glow(.appCyan, radius: 20, opacity: 0.4)

                Image(systemName: icon)
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .offset(y: floating ? -6 : 6)
            .animation(
                .easeInOut(duration: 2.6).repeatForever(autoreverses: true),
                value: floating
            )
            .onAppear { floating = true }

            VStack(spacing: AppSpacing.s) {
                Text(title)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.s)
            }

            // CTA hero opcional: cierre claro de la composición.
            if let actionTitle, let action {
                Button(action: action) {
                    if let actionIcon {
                        Label(actionTitle, systemImage: actionIcon)
                    } else {
                        Text(actionTitle)
                    }
                }
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
    .preferredColorScheme(.dark)
}
