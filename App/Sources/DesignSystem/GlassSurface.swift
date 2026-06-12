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

/// Modificador que aplica la superficie de vidrio estándar de la app.
struct GlassCardModifier: ViewModifier {
    /// Radio de esquina de la superficie.
    var cornerRadius: CGFloat = AppRadius.card

    /// Glow semántico opcional: solo para tarjetas con significado activo.
    var glowColor: Color? = nil

    func body(content: Content) -> some View {
        content
            // IMPLEMENTACIÓN ACTIVA: material ultrafino del sistema.
            // Compila en cualquier SDK reciente y se ve muy parecido a Liquid Glass.
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            // ALTERNATIVA NATIVA (iOS 26): para usar la API real de Liquid Glass,
            // comenta el `.background(...)` de arriba y descomenta la línea siguiente.
            // Verifica la firma exacta de la API en el SDK antes de activarla.
            // .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))

            // Borde sutil con gradiente para simular el brillo del cristal.
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                (glowColor ?? Color.white).opacity(glowColor == nil ? 0.35 : 0.5),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            // Sombra suave para dar profundidad a la tarjeta.
            .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
            // Glow semántico contenido, solo si la tarjeta lo pide.
            .shadow(
                color: (glowColor ?? .clear).opacity(glowColor == nil ? 0 : 0.18),
                radius: 18, x: 0, y: 0
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
