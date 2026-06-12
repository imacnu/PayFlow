//
//  Theme.swift
//  Subscription Guardian
//
//  Sistema de diseño tokenizado: color, gradientes, espaciado, radios,
//  sombras/glows y motion. Todas las pantallas deben consumir estos tokens
//  en lugar de valores sueltos para mantener la consistencia premium.
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

    // MARK: Acentos semánticos (valores exactos del mockup v2)

    /// Azul eléctrico principal (#1F6FEB). Acciones y navegación.
    static let electricBlue = Color(hex: "1F6FEB")

    /// Cian eléctrico (#39D5FF). Foco, selección, navegación activa.
    static let appCyan = Color(hex: "39D5FF")

    /// Cian profundo (#00B7FF). Inicio de los gradientes de acción.
    static let appCyanDeep = Color(hex: "00B7FF")

    /// Verde azulado neón (#1EFFC8). Cierre de gradientes y financiación.
    static let appTeal = Color(hex: "1EFFC8")

    /// Lima neón (#7BFF8F). Ahorro, éxito, activación positiva.
    static let appLime = Color(hex: "7BFF8F")

    /// Magenta neón (#FF4FB7). Alertas, vencimientos, estados críticos.
    static let appMagenta = Color(hex: "FF4FB7")

    /// Coral de alerta (#FF667F). Vencidos e incidencias.
    static let appCoral = Color(hex: "FF667F")

    /// Ámbar controlado (#FFAA48). Próximos eventos y avisos suaves.
    static let appAmber = Color(hex: "FFAA48")

    /// Texto secundario sobre fondo oscuro (#9AB2C6).
    static let appMuted = Color(hex: "9AB2C6")

    // MARK: Fondo y superficies

    /// Blanco cristal para fondos en modo claro (#F6F9FF).
    static let crystalWhite = Color(hex: "F6F9FF")

    /// Azul petróleo profundo: tono superior del fondo oscuro (#07111B).
    static let deepPetrol = Color(hex: "07111B")

    /// Azul petróleo medio: tramo central del fondo (#0B1F2B).
    static let midPetrol = Color(hex: "0B1F2B")

    /// Verde azulado oscuro: tono inferior del fondo oscuro (#0C2D36).
    static let darkTeal = Color(hex: "0C2D36")

    /// Grafito heredado; se mantiene como tono de reposo (#1C1F26).
    static let graphite = Color(hex: "1C1F26")
}

// MARK: - Gradientes

extension LinearGradient {
    /// Gradiente de acento principal: cian profundo → cian → teal (135º).
    static let appAccent = LinearGradient(
        colors: [.appCyanDeep, Color(hex: "35D7FF"), .appTeal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Columna luminosa para gráficos: verde lima arriba → azul abajo.
    static let luminousColumn = LinearGradient(
        colors: [Color(hex: "6FFFB0"), Color.appCyanDeep.opacity(0.95)],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Acento magenta → coral → ámbar para acciones de financiación.
    static let magentaAccent = LinearGradient(
        colors: [.appMagenta, .appCoral, Color(hex: "FFA560")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Conveniencias para ShapeStyle

extension ShapeStyle where Self == Color {
    static var electricBlue: Color { Color.electricBlue }
    static var appCyan: Color { Color.appCyan }
    static var appCyanDeep: Color { Color.appCyanDeep }
    static var appTeal: Color { Color.appTeal }
    static var appLime: Color { Color.appLime }
    static var appMagenta: Color { Color.appMagenta }
    static var appCoral: Color { Color.appCoral }
    static var appAmber: Color { Color.appAmber }
    static var appMuted: Color { Color.appMuted }
    static var crystalWhite: Color { Color.crystalWhite }
    static var graphite: Color { Color.graphite }
}

// MARK: - Espaciado

/// Escala de espaciado de la app: 4 / 8 / 12 / 16 / 20 / 24 / 32 / 40.
/// Compacta y precisa: en pantallas financieras el exceso de aire reduce
/// densidad útil.
enum AppSpacing {
    static let xxs: CGFloat = 4
    static let s: CGFloat = 8
    static let sm: CGFloat = 12
    static let m: CGFloat = 16
    static let ml: CGFloat = 20
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 40
}

// MARK: - Radios de esquina

/// Radios jerarquizados: pequeño para chips, medio para inputs y tiles,
/// grande para cards y paneles; cápsula para CTAs y navegación.
enum AppRadius {
    static let small: CGFloat = 10
    static let medium: CGFloat = 14
    static let large: CGFloat = 24

    /// Alias heredados.
    static let card: CGFloat = large
    static let control: CGFloat = medium
}

// MARK: - Sombras y glows

/// Sombras tokenizadas por función: elevación suave, flotación y glows
/// semánticos. El glow debe reservarse a acciones y estados con significado.
extension View {
    /// Elevación mínima de superficie.
    func softShadow() -> some View {
        shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
    }

    /// Flotación marcada para cards destacadas y navegación inferior.
    func floatingShadow() -> some View {
        shadow(color: Color.black.opacity(0.28), radius: 24, x: 0, y: 12)
    }

    /// Glow semántico controlado alrededor del elemento.
    func glow(_ color: Color, radius: CGFloat = 14, opacity: Double = 0.45) -> some View {
        shadow(color: color.opacity(opacity), radius: radius, x: 0, y: 0)
    }
}

// MARK: - Motion

/// Lenguaje de movimiento tokenizado. Las animaciones deben parecer físicas:
/// respuesta táctil inmediata, transiciones con intención, nada arbitrario.
enum AppMotion {
    /// Respuesta táctil inmediata (pressed states).
    static let tap: Animation = .spring(response: 0.25, dampingFraction: 0.7)

    /// Transición estándar entre estados.
    static let standard: Animation = .spring(response: 0.45, dampingFraction: 0.8)

    /// Transición expresiva para entradas de pantalla y métricas.
    static let expressive: Animation = .spring(response: 0.6, dampingFraction: 0.8)

    /// Retardo entre elementos de una cascada de entrada.
    static let cascadeStep: Double = 0.06
}

// MARK: - Entrada en cascada

/// Modificador de entrada: fade + ligera elevación, con retardo en cascada
/// según el índice del elemento dentro de la pantalla.
private struct CascadeIn: ViewModifier {
    let index: Int

    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 14)
            .onAppear {
                withAnimation(AppMotion.expressive.delay(Double(index) * AppMotion.cascadeStep)) {
                    visible = true
                }
            }
    }
}

extension View {
    /// Entrada en cascada de los módulos de una pantalla: fade + elevación
    /// suave con retardo secuencial por índice.
    func cascadeIn(_ index: Int) -> some View {
        modifier(CascadeIn(index: index))
    }
}
