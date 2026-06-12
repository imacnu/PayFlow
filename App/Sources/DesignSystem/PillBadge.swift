//
//  PillBadge.swift
//  Subscription Guardian
//
//  Insignia en forma de píldora para etiquetas cortas (estado, categoría, etc.).
//

import SwiftUI

/// Insignia compacta con fondo teñido y texto en el color de acento.
struct PillBadge: View {
    let text: String
    var tint: Color = .appCyan

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, AppSpacing.s)
            .padding(.vertical, 4)
            .background(tint.opacity(0.15), in: Capsule())
    }
}

// MARK: - Vista previa

#Preview {
    ZStack {
        AppBackground()

        HStack(spacing: AppSpacing.s) {
            PillBadge(text: "Active")
            PillBadge(text: "Trial", tint: .orange)
            PillBadge(text: "Canceled", tint: .secondary)
            PillBadge(text: "Annual", tint: .appCyan)
        }
        .glassCard()
        .padding(AppSpacing.l)
    }
}
