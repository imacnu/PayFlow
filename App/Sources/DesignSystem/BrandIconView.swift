//
//  BrandIconView.swift
//  Subscription Guardian
//
//  Icono de marca de un servicio: símbolo SF o monograma sobre fondo de color.
//

import SwiftUI

/// Icono cuadrado redondeado para la marca de una suscripción.
/// Muestra un SF Symbol si está disponible; si no, el monograma.
struct BrandIconView: View {
    /// Nombre de SF Symbol opcional.
    let symbol: String?
    /// Monograma de respaldo (p. ej. "NF" para Netflix).
    let monogram: String
    /// Color de marca en formato hexadecimal "RRGGBB".
    let colorHex: String
    var size: CGFloat = 44

    private var brandColor: Color {
        Color(hex: colorHex)
    }

    var body: some View {
        ZStack {
            // Fondo con gradiente del color de marca hacia una variante más oscura
            // (se consigue superponiendo negro con opacidad en la parte inferior).
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(brandColor)

            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.18),
                            Color.black.opacity(0.18)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Contenido: símbolo si existe, monograma en caso contrario.
            if let symbol, !symbol.isEmpty {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(.white)
            } else {
                Text(monogram)
                    .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(size * 0.12)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Vista previa

#Preview {
    ZStack {
        AppBackground()

        HStack(spacing: AppSpacing.m) {
            BrandIconView(symbol: "play.tv.fill", monogram: "NF", colorHex: "E50914")
            BrandIconView(symbol: nil, monogram: "SP", colorHex: "1DB954")
            BrandIconView(symbol: "music.note", monogram: "AM", colorHex: "FA243C", size: 60)
            BrandIconView(symbol: "", monogram: "iC", colorHex: "1F6FEB")
        }
        .padding(AppSpacing.l)
    }
}
