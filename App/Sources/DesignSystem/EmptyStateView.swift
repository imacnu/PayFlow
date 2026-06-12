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
            // Orbe hero del mockup: cuadrado redondeado con gradiente cian,
            // brillo radial superior izquierdo y flotación lenta.
            ZStack {
                // Halo de luz ambiental detrás del orbe.
                Circle()
                    .fill(Color.appCyan.opacity(0.25))
                    .frame(width: 150, height: 150)
                    .blur(radius: 40)

                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.appCyan.opacity(0.4),
                                Color.appCyanDeep.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        // Reflejo radial en la esquina superior izquierda.
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(0.28),
                                        Color.white.opacity(0.06),
                                        Color.white.opacity(0.0)
                                    ],
                                    center: .init(x: 0.3, y: 0.3),
                                    startRadius: 4,
                                    endRadius: 90
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.35), Color.white.opacity(0.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                    .frame(width: 118, height: 118)
                    .glow(.appCyan, radius: 22, opacity: 0.35)

                Image(systemName: icon)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(Color(hex: "EFFCFF"))
                    .glow(.appCyan, radius: 12, opacity: 0.5)
            }
            .offset(y: floating ? -6 : 6)
            .animation(
                .easeInOut(duration: 2.6).repeatForever(autoreverses: true),
                value: floating
            )
            .onAppear { floating = true }

            VStack(spacing: AppSpacing.s) {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .kerning(-0.5)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.system(size: 16))
                    .lineSpacing(3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.m)
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
