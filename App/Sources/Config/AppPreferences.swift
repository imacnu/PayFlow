//
//  AppPreferences.swift
//  Subscription Guardian
//
//  Preferencias de usuario persistidas en UserDefaults vía @AppStorage:
//  apariencia (claro/oscuro/sistema) e idioma de la interfaz.
//

import SwiftUI

/// Apariencia de la interfaz: seguir al sistema o forzar claro/oscuro.
enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    static let storageKey = "pref.appearance"

    var id: String { rawValue }

    /// Esquema de color a aplicar con `.preferredColorScheme` (nil = sistema).
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var localizedName: String {
        switch self {
        case .system:
            return String(localized: "appearance.system", defaultValue: "Sistema")
        case .light:
            return String(localized: "appearance.light", defaultValue: "Claro")
        case .dark:
            return String(localized: "appearance.dark", defaultValue: "Oscuro")
        }
    }
}

/// Idioma de la interfaz. El cambio se materializa escribiendo
/// `AppleLanguages`, por lo que requiere reiniciar la app.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case spanish = "es"
    case english = "en"

    static let storageKey = "pref.language"

    var id: String { rawValue }

    /// Nombre del idioma en su propio idioma (endónimo), sin localizar.
    var displayName: String {
        switch self {
        case .system:
            return String(localized: "language.system", defaultValue: "Sistema")
        case .spanish:
            return "Castellano"
        case .english:
            return "English"
        }
    }

    /// Aplica la preferencia sobre los idiomas de la app. iOS la tiene en
    /// cuenta en el siguiente arranque.
    func apply() {
        switch self {
        case .system:
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        case .spanish, .english:
            UserDefaults.standard.set([rawValue], forKey: "AppleLanguages")
        }
    }
}
