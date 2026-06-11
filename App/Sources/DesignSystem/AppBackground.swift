//
//  AppBackground.swift
//  Subscription Guardian
//
//  Fondo en capas de la app: color base más círculos difuminados de acento,
//  adaptado automáticamente a modo claro y oscuro.
//

import SwiftUI

/// Fondo decorativo de la app con color base y manchas de gradiente difuminadas.
struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Color base según el esquema de color.
                (colorScheme == .dark ? Color.graphite : Color.crystalWhite)

                // Mancha azul superior izquierda.
                Circle()
                    .fill(Color.electricBlue.opacity(0.25))
                    .frame(width: proxy.size.width * 0.9,
                           height: proxy.size.width * 0.9)
                    .position(x: proxy.size.width * 0.15,
                              y: proxy.size.height * 0.05)
                    .blur(radius: 80)

                // Mancha cian a la derecha.
                Circle()
                    .fill(Color.appCyan.opacity(0.25))
                    .frame(width: proxy.size.width * 0.8,
                           height: proxy.size.width * 0.8)
                    .position(x: proxy.size.width * 0.95,
                              y: proxy.size.height * 0.35)
                    .blur(radius: 80)

                // Mancha azul inferior para equilibrar la composición.
                Circle()
                    .fill(Color.electricBlue.opacity(0.18))
                    .frame(width: proxy.size.width * 0.9,
                           height: proxy.size.width * 0.9)
                    .position(x: proxy.size.width * 0.3,
                              y: proxy.size.height * 0.95)
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
