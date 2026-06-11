//
//  GlassSurface.swift
//  Subscription Guardian
//
//  ÚNICO punto de entrada para el estilo "Liquid Glass" de la app.
//  Ningún otro componente debe llamar a glassEffect directamente:
//  todos deben usar la extensión `.glassCard(...)` definida aquí.
//

import SwiftUI

/// Modificador que aplica la superficie de vidrio estándar de la app.
struct GlassCardModifier: ViewModifier {
    /// Radio de esquina de la superficie.
    var cornerRadius: CGFloat = AppRadius.card

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
                                Color.white.opacity(0.35),
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
    }
}

// MARK: - Extensión de conveniencia

extension View {
    /// Aplica relleno interior y la superficie de vidrio estándar de la app.
    /// Este es el único camino permitido hacia el estilo glass.
    func glassCard(
        cornerRadius: CGFloat = AppRadius.card,
        padding: CGFloat = AppSpacing.m
    ) -> some View {
        self
            .padding(padding)
            .modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Vista previa

#Preview {
    ZStack {
        AppBackground()

        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text("Glass Surface")
                .font(.headline)
            Text("Ultra thin material + stroke + shadow")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .glassCard()
        .padding(AppSpacing.l)
    }
}
