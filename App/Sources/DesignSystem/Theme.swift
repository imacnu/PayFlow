//
//  Theme.swift
//  Subscription Guardian
//
//  Paleta de colores, gradientes y constantes de espaciado del sistema de diseño.
//

import SwiftUI

// MARK: - Color (hex)

extension Color {
    /// Crea un color a partir de una cadena hexadecimal "RRGGBB" (con o sin "#").
    init(hex: String) {
        let cleaned = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }

    // MARK: Paleta de la app

    /// Azul eléctrico principal (#1F6FEB).
    static let electricBlue = Color(hex: "1F6FEB")

    /// Cian de acento (#38E1FF).
    static let appCyan = Color(hex: "38E1FF")

    /// Blanco cristal para fondos en modo claro (#F6F9FF).
    static let crystalWhite = Color(hex: "F6F9FF")

    /// Grafito para fondos en modo oscuro (#1C1F26).
    static let graphite = Color(hex: "1C1F26")
}

// MARK: - Gradientes

extension LinearGradient {
    /// Gradiente de acento principal de la app (azul eléctrico → cian).
    static let appAccent = LinearGradient(
        colors: [.electricBlue, .appCyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Conveniencias para ShapeStyle

extension ShapeStyle where Self == Color {
    /// Acceso rápido al azul eléctrico como ShapeStyle.
    static var electricBlue: Color { Color.electricBlue }

    /// Acceso rápido al cian de la app como ShapeStyle.
    static var appCyan: Color { Color.appCyan }

    /// Acceso rápido al blanco cristal como ShapeStyle.
    static var crystalWhite: Color { Color.crystalWhite }

    /// Acceso rápido al grafito como ShapeStyle.
    static var graphite: Color { Color.graphite }
}

// MARK: - Espaciado

/// Escala de espaciado estándar de la app.
enum AppSpacing {
    static let s: CGFloat = 8
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
}

// MARK: - Radios de esquina

/// Radios de esquina estándar para superficies y controles.
enum AppRadius {
    static let card: CGFloat = 24
    static let control: CGFloat = 14
}
