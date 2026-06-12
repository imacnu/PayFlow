//
//  AppBackground.swift
//  Subscription Guardian
//
//  Fondo atmosférico de la app: degradado profundo (azul petróleo → verde
//  azulado, nunca negro puro) con manchas de luz difuminadas que dan vida
//  y profundidad. Se adapta a modo claro y oscuro.
//

import SwiftUI

/// Fondo decorativo en capas: degradado base + luz ambiental difuminada.
struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Degradado base 145º del mockup: #07111B → #0B1F2B → #0C2D36.
                if colorScheme == .dark {
                    LinearGradient(
                        stops: [
                            .init(color: .deepPetrol, location: 0),
                            .init(color: .midPetrol, location: 0.36),
                            .init(color: .darkTeal, location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    LinearGradient(
                        colors: [.crystalWhite, Color(hex: "E4F0F4")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

                // Foco azul superior izquierda (rgba(42,128,255,.18) @ 18% 12%).
                Circle()
                    .fill(Color(hex: "2A80FF").opacity(colorScheme == .dark ? 0.18 : 0.20))
                    .frame(width: proxy.size.width * 1.0,
                           height: proxy.size.width * 1.0)
                    .position(x: proxy.size.width * 0.18,
                              y: proxy.size.height * 0.12)
                    .blur(radius: 80)

                // Foco teal superior derecha (rgba(16,255,202,.18) @ 82% 18%).
                Circle()
                    .fill(Color(hex: "10FFCA").opacity(colorScheme == .dark ? 0.18 : 0.16))
                    .frame(width: proxy.size.width * 1.0,
                           height: proxy.size.width * 1.0)
                    .position(x: proxy.size.width * 0.82,
                              y: proxy.size.height * 0.18)
                    .blur(radius: 85)

                // Foco cian inferior (rgba(0,183,255,.12) @ 58% 78%).
                Circle()
                    .fill(Color.appCyanDeep.opacity(colorScheme == .dark ? 0.12 : 0.10))
                    .frame(width: proxy.size.width * 0.9,
                           height: proxy.size.width * 0.9)
                    .position(x: proxy.size.width * 0.58,
                              y: proxy.size.height * 0.78)
                    .blur(radius: 80)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Extensión de conveniencia

extension View {
    /// Coloca el fondo de la app detrás del contenido.
    func appBackground() -> some View {
        ZStack {
            AppBackground()
            self
        }
    }
}

// MARK: - Vista previa

#Preview("Claro") {
    Text("Subscription Guardian")
        .font(.title2.bold())
        .appBackground()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    Text("Subscription Guardian")
        .font(.title2.bold())
        .appBackground()
        .preferredColorScheme(.dark)
}
