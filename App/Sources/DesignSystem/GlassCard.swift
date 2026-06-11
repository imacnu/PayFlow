//
//  GlassCard.swift
//  Subscription Guardian
//
//  Contenedor genérico que envuelve cualquier contenido en una tarjeta de vidrio.
//

import SwiftUI

/// Tarjeta de vidrio genérica: envuelve el contenido con `.glassCard(...)`.
struct GlassCard<Content: View>: View {
    private let cornerRadius: CGFloat
    private let padding: CGFloat
    private let content: Content

    init(
        cornerRadius: CGFloat = AppRadius.card,
        padding: CGFloat = AppSpacing.m,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .glassCard(cornerRadius: cornerRadius, padding: padding)
    }
}

// MARK: - Vista previa

#Preview {
    ZStack {
        AppBackground()

        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.s) {
                Text("Monthly total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("$42.97")
                    .font(.title2.bold())
            }
        }
        .padding(AppSpacing.l)
    }
}
