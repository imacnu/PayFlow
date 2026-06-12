//
//  PrimaryButtonStyle.swift
//  Subscription Guardian
//
//  Estilos de botón del sistema: CTA principal hero (cápsula con gradiente
//  y glow cian) y estilo pulsable para tarjetas y tiles.
//

import SwiftUI

/// Estilo de botón principal de la app: cierre de flujo con presencia,
/// glow controlado y respuesta táctil física. Admite acento alternativo
/// (p. ej. magenta para financiación).
struct PrimaryButtonStyle: ButtonStyle {
    var gradient: LinearGradient = .appAccent
    var glowColor: Color = .appCyan

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, AppSpacing.l)
            .frame(minHeight: 52)
            .background(gradient, in: Capsule())
            .overlay(
                // Brillo superior sutil que refuerza la materialidad.
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.5), Color.white.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            // Glow de acción principal; se hunde al pulsar.
            .shadow(
                color: glowColor.opacity(configuration.isPressed ? 0.2 : 0.4),
                radius: configuration.isPressed ? 8 : 16,
                x: 0,
                y: configuration.isPressed ? 3 : 8
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(AppMotion.tap, value: configuration.isPressed)
    }
}

/// Estilo pulsable para tarjetas, tiles e iconos: compresión leve,
/// profundización de sombra y rebote mínimo al soltar.
struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(AppMotion.tap, value: configuration.isPressed)
    }
}

// MARK: - Accesos abreviados

extension ButtonStyle where Self == PrimaryButtonStyle {
    /// Permite escribir `.buttonStyle(.primary)`.
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }

    /// Variante magenta para acciones de alto impacto de financiación.
    static var primaryMagenta: PrimaryButtonStyle {
        PrimaryButtonStyle(gradient: .magentaAccent, glowColor: .appMagenta)
    }
}

extension ButtonStyle where Self == PressableCardStyle {
    /// Permite escribir `.buttonStyle(.pressableCard)`.
    static var pressableCard: PressableCardStyle { PressableCardStyle() }
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

            Button {
            } label: {
                Text("Pressable card")
                    .glassCard()
            }
            .buttonStyle(.pressableCard)
        }
        .padding(AppSpacing.l)
    }
    .preferredColorScheme(.dark)
}
