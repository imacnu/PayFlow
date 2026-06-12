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
                // Degradado base: superficie rica en profundidad, con
                // transición tonal para que el fondo "respire".
                if colorScheme == .dark {
                    LinearGradient(
                        colors: [.deepPetrol, .darkTeal, Color(hex: "111A24")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                } else {
                    LinearGradient(
                        colors: [.crystalWhite, Color(hex: "EAF2F6")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

                // Luz cian superior izquierda: foco principal de atmósfera.
                Circle()
                    .fill(Color.appCyan.opacity(colorScheme == .dark ? 0.16 : 0.22))
                    .frame(width: proxy.size.width * 0.9,
                           height: proxy.size.width * 0.9)
                    .position(x: proxy.size.width * 0.15,
                              y: proxy.size.height * 0.05)
                    .blur(radius: 90)

                // Azul eléctrico a la derecha, zona media.
                Circle()
                    .fill(Color.electricBlue.opacity(colorScheme == .dark ? 0.18 : 0.20))
                    .frame(width: proxy.size.width * 0.8,
                           height: proxy.size.width * 0.8)
                    .position(x: proxy.size.width * 0.95,
                              y: proxy.size.height * 0.35)
                    .blur(radius: 90)

                // Verde azulado inferior para cerrar la composición en calma.
                Circle()
                    .fill(Color(hex: "1C6E63").opacity(colorScheme == .dark ? 0.22 : 0.14))
                    .frame(width: proxy.size.width * 0.9,
                           height: proxy.size.width * 0.9)
                    .position(x: proxy.size.width * 0.3,
                              y: proxy.size.height * 0.95)
                    .blur(radius: 90)
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
