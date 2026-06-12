//
//  AnimatedProgressBar.swift
//  Subscription Guardian
//
//  Barra de progreso horizontal con animación de resorte al aparecer y al cambiar.
//

import SwiftUI

/// Barra de progreso en forma de cápsula con animación de resorte.
struct AnimatedProgressBar: View {
    /// Progreso entre 0.0 y 1.0.
    let progress: Double
    var tint: Color = .appCyan
    var height: CGFloat = 10

    /// Progreso animado interno; se mueve hacia `progress` con un resorte.
    @State private var animatedProgress: Double = 0

    /// Valor de progreso acotado a [0, 1].
    private var clampedProgress: Double {
        min(max(animatedProgress, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                // Pista de fondo.
                Capsule()
                    .fill(.quaternary)

                // Relleno luminoso proporcional al progreso.
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.75), tint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: proxy.size.width * clampedProgress)
                    .glow(tint, radius: 6, opacity: 0.35)
            }
        }
        .frame(height: height)
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

        VStack(spacing: AppSpacing.m) {
            AnimatedProgressBar(progress: 0.25)
            AnimatedProgressBar(progress: 0.6, tint: .appCyan)
            AnimatedProgressBar(progress: 0.9, tint: .orange, height: 14)
        }
        .glassCard()
        .padding(AppSpacing.l)
    }
}
