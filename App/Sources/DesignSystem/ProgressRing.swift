//
//  ProgressRing.swift
//  Subscription Guardian
//
//  Anillo de progreso circular con animación de resorte.
//

import SwiftUI

/// Anillo de progreso circular con extremos redondeados y animación de resorte.
struct ProgressRing: View {
    /// Progreso entre 0.0 y 1.0.
    let progress: Double
    var lineWidth: CGFloat = 8
    var tint: Color = .appCyan
    var size: CGFloat = 64

    /// Progreso animado interno; se mueve hacia `progress` con un resorte.
    @State private var animatedProgress: Double = 0

    /// Valor de progreso acotado a [0, 1].
    private var clampedProgress: Double {
        min(max(animatedProgress, 0), 1)
    }

    var body: some View {
        ZStack {
            // Anillo de fondo.
            Circle()
                .stroke(.quaternary, lineWidth: lineWidth)

            // Anillo de progreso, comenzando desde arriba.
            Circle()
                .trim(from: 0, to: CGFloat(clampedProgress))
                .stroke(
                    tint,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Vista previa

#Preview {
    ZStack {
        AppBackground()

        HStack(spacing: AppSpacing.l) {
            ProgressRing(progress: 0.3)
            ProgressRing(progress: 0.65, tint: .appCyan)
            ProgressRing(progress: 0.9, lineWidth: 12, tint: .orange, size: 90)
        }
        .glassCard()
        .padding(AppSpacing.l)
    }
}
