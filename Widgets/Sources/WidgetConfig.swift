import SwiftUI

/// Configuración local de la extensión de widgets.
///
/// IMPORTANTE: `appGroupID` y `widgetSnapshotKey` deben coincidir exactamente
/// con los valores de `AppConfig` (App/Sources/Config/AppConfig.swift).
/// La extensión no compila las fuentes de la app, por eso se redefinen aquí.
enum WidgetConfig {
    /// Identificador del App Group compartido con la app principal.
    static let appGroupID = "group.com.example.subscriptionguardian"

    /// Clave en el UserDefaults compartido donde la app publica el snapshot.
    static let widgetSnapshotKey = "widget.snapshot.v1"

    // MARK: - Colores de acento (lenguaje visual financiero premium)

    /// Azul eléctrico #1F6FEB.
    static let electricBlue = Color(hex: 0x1F6FEB)

    /// Cian #38E1FF.
    static let appCyan = Color(hex: 0x38E1FF)
}

extension Color {
    /// Inicializador mínimo a partir de un valor hexadecimal RGB de 24 bits.
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}
