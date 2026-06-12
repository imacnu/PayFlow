//
//  GlassSurface.swift
//  Subscription Guardian
//
//  ÚNICO punto de entrada para las superficies del sistema de diseño:
//  - Glass (ver información): tarjetas de vidrio con luz y lectura.
//  - Inset (editar información): paneles excavados, táctiles, neumórficos.
//  Ningún otro componente debe construir estos efectos por su cuenta.
//

import SwiftUI

/// Modificador que aplica la superficie de vidrio del mockup v2: relleno
/// degradado claro sobre material, borde azul translúcido, brillo interior
/// superior y sombra profunda. Es lo que evita el efecto "panel negro plano".
struct GlassCardModifier: ViewModifier {
    /// Radio de esquina de la superficie.
    var cornerRadius: CGFloat = AppRadius.card

    /// Glow semántico opcional: solo para tarjetas con significado activo.
    var glowColor: Color? = nil

    @Environment(\.colorScheme) private var colorScheme

    /// Degradado del cristal: blanco 7% → 3% en oscuro (mockup), versión
    /// clara equivalente en modo claro.
    private var glassFill: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [Color.white.opacity(0.07), Color.white.opacity(0.03)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        return LinearGradient(
            colors: [Color.white.opacity(0.75), Color.white.opacity(0.45)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Borde translúcido azulado del mockup: rgba(168,227,255,.12).
    private var strokeColor: Color {
        if let glowColor { return glowColor.opacity(0.4) }
        return colorScheme == .dark
            ? Color(hex: "A8E3FF").opacity(0.12)
            : Color(hex: "5A8FAE").opacity(0.25)
    }

    func body(content: Content) -> some View {
        content
            // Blur de fondo con el degradado de cristal por encima.
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(glassFill)
                }
            )
            // Borde azulado + brillo interior en la arista superior.
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(strokeColor, lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.18 : 0.8),
                                Color.white.opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .center
                        ),
                        lineWidth: 1
                    )
            )
            // Sombra profunda del mockup (0 18px 38px rgba(0,0,0,.34)).
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.34 : 0.12),
                radius: 19, x: 0, y: 9
            )
            // Glow semántico contenido, solo si la tarjeta lo pide.
            .shadow(
                color: (glowColor ?? .clear).opacity(glowColor == nil ? 0 : 0.2),
                radius: 20, x: 0, y: 0
            )
    }
}

/// Superficie excavada (inset) para el lenguaje de "editar información":
/// campos, selectores y controles. Más profundidad táctil, menos vidrio.
struct InsetPanelModifier: ViewModifier {
    var cornerRadius: CGFloat = AppRadius.medium

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        colorScheme == .dark
                            ? Color.black.opacity(0.28)
                            : Color(hex: "DDE6EC").opacity(0.6)
                    )
            )
            // Borde superior oscuro + inferior claro: sensación de excavado.
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(colorScheme == .dark ? 0.45 : 0.12),
                                Color.white.opacity(colorScheme == .dark ? 0.08 : 0.55)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Extensiones de conveniencia

extension View {
    /// Aplica relleno interior y la superficie de vidrio estándar de la app.
    /// Este es el único camino permitido hacia el estilo glass.
    /// - Parameter glow: color de glow semántico opcional (solo tarjetas con
    ///   significado activo; la mayoría deben ir sin glow).
    func glassCard(
        cornerRadius: CGFloat = AppRadius.card,
        padding: CGFloat = AppSpacing.m,
        glow: Color? = nil
    ) -> some View {
        self
            .padding(padding)
            .modifier(GlassCardModifier(cornerRadius: cornerRadius, glowColor: glow))
    }

    /// Superficie excavada para formularios y controles de edición.
    func insetPanel(
        cornerRadius: CGFloat = AppRadius.medium,
        padding: CGFloat = AppSpacing.s
    ) -> some View {
        self
            .padding(padding)
            .modifier(InsetPanelModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Vista previa

#Preview {
    ZStack {
        AppBackground()

        VStack(spacing: AppSpacing.l) {
            VStack(alignment: .leading, spacing: AppSpacing.s) {
                Text("Glass Surface")
                    .font(.headline)
                Text("Ultra thin material + stroke + shadow")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .glassCard()

            VStack(alignment: .leading, spacing: AppSpacing.s) {
                Text("Glass + glow")
                    .font(.headline)
            }
            .glassCard(glow: .appCyan)

            Text("Inset panel (editar)")
                .insetPanel()
        }
        .padding(AppSpacing.l)
    }
    .preferredColorScheme(.dark)
}
